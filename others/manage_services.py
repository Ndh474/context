import os
import queue
import signal
import subprocess
import threading
import tkinter as tk
import webbrowser
from tkinter import scrolledtext, ttk, messagebox
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional

# --- Configuration ---


@dataclass
class ServiceConfig:
    name: str
    path: str
    command: List[str]
    color: str
    url: Optional[str] = None
    actions: List[Dict] = field(default_factory=list)


# --- Database Config ---
DB_USER = "postgres"
DB_PASSWORD = "postgres"
DB_NAME = "fuacs_dev"

SERVICES_CONFIG = [
    ServiceConfig(
        name="RECOGNITION",
        path="recognition-service",
        command=[
            "poetry",
            "run",
            "uvicorn",
            "src.recognition_service.main:app",
            "--host",
            "0.0.0.0",
            "--port",
            "8000",
            "--reload",
        ],
        color="cyan",
        url=None,
    ),
    ServiceConfig(
        name="FRONTEND",
        path="frontend-web",
        command=["cmd", "/c", "npm", "run", "dev"],
        color="green",
        url="http://localhost:3000",
    ),
    ServiceConfig(
        name="BACKEND",
        path="backend",
        command=["cmd", "/c", "mvnw.cmd", "spring-boot:run"],
        color="#D4AF37",  # Gold/Yellowish
        url=None,
        actions=[
            {
                "label": "💣 Reset DB & Run",
                "command": f'psql "postgres://{DB_USER}:{DB_PASSWORD}@127.0.0.1:5432/{DB_NAME}" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"',
                "restart": True,
            }
        ],
    ),
]

# --- Logic ---


class ServiceManager:
    def __init__(
        self,
        config: ServiceConfig,
        log_queue: queue.Queue,
        status_callback,
        clear_log_callback=None,
    ):
        self.config = config
        self.log_queue = log_queue
        self.status_callback = status_callback
        self.clear_log_callback = clear_log_callback
        self.process: Optional[subprocess.Popen] = None
        self.working_dir = Path.cwd() / config.path
        self._stop_event = threading.Event()

    def start(self, extra_args: List[str] = None):
        if self.is_running():
            return

        if self.clear_log_callback:
            self.clear_log_callback(self.config.name)

        if not self.working_dir.exists():
            self._log(f"Error: Directory not found: {self.working_dir}", "red")
            return

        self._log(f"Starting {self.config.name}...", "black")

        cmd = self.config.command.copy()
        if extra_args:
            # Append extra args
            cmd.extend(extra_args)

        try:
            self.process = subprocess.Popen(
                cmd,
                cwd=str(self.working_dir),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                env=dict(os.environ, PYTHONIOENCODING="utf-8"),
                encoding="utf-8",
                errors="replace",
                text=True,
                bufsize=1,
            )
            self.status_callback(self.config.name, True)

            # Start background threads to read streams
            self._stop_event.clear()
            threading.Thread(
                target=self._read_stream, args=(self.process.stdout,), daemon=True
            ).start()
            threading.Thread(
                target=self._read_stream, args=(self.process.stderr,), daemon=True
            ).start()

        except Exception as e:
            self._log(f"Failed to start: {e}", "red")
            self.status_callback(self.config.name, False)

    def stop(self):
        if not self.is_running():
            return

        self._log(f"Stopping {self.config.name}...", "red")

        try:
            # Taskkill for windows tree kill
            subprocess.run(
                f"taskkill /F /T /PID {self.process.pid}",
                shell=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception as e:
            self._log(f"Error stopping: {e}", "red")

        if self.process:
            self.process.poll()
            if self.process.returncode is None:
                try:
                    self.process.terminate()
                except:
                    pass

        self.process = None
        self.status_callback(self.config.name, False)
        self._log("Stopped", "black")

    def is_running(self):
        return self.process is not None and self.process.poll() is None

    def _read_stream(self, stream):
        if not stream:
            return

        for line in stream:
            if self._stop_event.is_set():
                break
            self._log(line.rstrip(), "black")

        # Check if process died
        if not self.is_running() and self.process:
            pass

    def _log(self, message, color):
        self.log_queue.put((self.config.name, message, color))


# --- GUI ---


class ServiceApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("FUACS System Manager")
        self.geometry("1100x600")

        self.managers: Dict[str, ServiceManager] = {}
        self.log_queue = queue.Queue()
        self.current_service = SERVICES_CONFIG[0].name
        self.log_buffers: Dict[str, List[str]] = {s.name: [] for s in SERVICES_CONFIG}

        self._setup_ui()
        self._init_managers()
        self._process_queue()

    def open_service_url(self, url):
        webbrowser.open(url)

    def _setup_ui(self):
        # Configure layout (Sidebar + Main)
        self.columnconfigure(1, weight=1)
        self.rowconfigure(0, weight=1)

        # --- Sidebar ---
        sidebar = ttk.Frame(self, padding="10", width=300)
        sidebar.grid(row=0, column=0, sticky="ns")
        sidebar.pack_propagate(False)  # Fixed width

        # Global Controls
        ttk.Label(sidebar, text="GLOBAL CONTROLS", font=("Arial", 10, "bold")).pack(
            fill="x", pady=(0, 5)
        )

        btn_frame = ttk.Frame(sidebar)
        btn_frame.pack(fill="x", pady=5)

        ttk.Button(btn_frame, text="▶ Start All", command=self.start_all).pack(
            side="left", fill="x", expand=True, padx=(0, 2)
        )
        ttk.Button(btn_frame, text="☠ Kill All", command=self.kill_all_orphans).pack(
            side="left", fill="x", expand=True, padx=(2, 0)
        )

        ttk.Separator(sidebar, orient="horizontal").pack(fill="x", pady=15)

        # Services List
        ttk.Label(sidebar, text="SERVICES", font=("Arial", 10, "bold")).pack(
            fill="x", pady=(0, 10)
        )

        self.service_widgets = {}  # Map name -> {card, btn_action, status_lbl}

        for conf in SERVICES_CONFIG:
            # Card Frame
            card = ttk.LabelFrame(sidebar, text=conf.name, padding="5")
            card.pack(fill="x", pady=5)

            # Inner Layout
            # Status Indicator + Action Button
            ctrl_frame = ttk.Frame(card)
            ctrl_frame.pack(fill="x", pady=2)

            # Status Label
            lbl_status = ttk.Label(
                ctrl_frame, text="STOPPED", foreground="gray", font=("Arial", 8)
            )
            lbl_status.pack(side="left", padx=5)

            # Open URL Button
            if conf.url:
                btn_open = ttk.Button(
                    ctrl_frame,
                    text="🌐",
                    width=3,
                    command=lambda u=conf.url: self.open_service_url(u),
                )
                btn_open.pack(side="right", padx=2)

            # View Log Button
            btn_view = ttk.Button(
                ctrl_frame,
                text="View Logs",
                command=lambda n=conf.name: self.show_service(n),
            )
            btn_view.pack(side="right", padx=2)

            # Action Button (Run/Stop)
            btn_action = ttk.Button(
                card, text="▶ Run", command=lambda n=conf.name: self.toggle_service(n)
            )
            btn_action.pack(fill="x", pady=(5, 0))

            # Custom Actions (Buttons)
            if conf.actions:
                for action in conf.actions:
                    ttk.Button(
                        card,
                        text=action["label"],
                        command=lambda n=conf.name, a=action: self.run_custom_action(
                            n, a
                        ),
                    ).pack(fill="x", pady=(2, 0))

            self.service_widgets[conf.name] = {"status": lbl_status, "btn": btn_action}

        # --- Main Content ---
        main_frame = ttk.Frame(self, padding="0")
        main_frame.grid(row=0, column=1, sticky="nsew")

        # Header for Log
        self.header_frame = ttk.Frame(main_frame, padding="5")
        self.header_frame.pack(fill="x")

        self.lbl_current = ttk.Label(
            self.header_frame,
            text=f"Logs: {self.current_service}",
            font=("Arial", 11, "bold"),
        )
        self.lbl_current.pack(side="left")

        ttk.Button(
            self.header_frame, text="Clear Logs", command=self.clear_current_log
        ).pack(side="right")

        # Log Area
        self.log_area = scrolledtext.ScrolledText(
            main_frame,
            state="disabled",
            font=("Consolas", 10),
            bg="#1e1e1e",
            fg="#d4d4d4",
        )
        self.log_area.pack(fill="both", expand=True)

    def toggle_service(self, name):
        mgr = self.managers[name]
        if mgr.is_running():
            threading.Thread(target=mgr.stop).start()
        else:
            threading.Thread(target=mgr.start).start()

    def run_custom_action(self, name, action_config):
        # Action config can be: {"label": "...", "arg": "..."} (Legacy/Default)
        # or {"label": "...", "command": "...", "restart": True}

        mgr = self.managers[name]
        # Force switch to this service to see logs
        self.show_service(name)

        def _action_thread():
            try:
                if mgr.is_running():
                    mgr.stop()
                    # Wait a bit for port release if needed
                    import time

                    time.sleep(1)

                # If it's a shell command type
                if "command" in action_config:
                    cmd = action_config["command"]
                    mgr.log_queue.put(
                        (name, f"Running action: {action_config['label']}...", "yellow")
                    )
                    mgr.log_queue.put((name, f"> {cmd}", "gray"))

                    try:
                        # Run the command synchronously
                        res = subprocess.run(
                            cmd,
                            shell=True,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE,
                            text=True,
                            encoding="utf-8",
                            errors="replace",
                        )
                        if res.stdout:
                            mgr.log_queue.put((name, res.stdout.strip(), "white"))
                        if res.stderr:
                            mgr.log_queue.put((name, res.stderr.strip(), "red"))

                        if res.returncode != 0:
                            err_msg = (
                                f"Action failed with code {res.returncode}. check logs."
                            )
                            mgr.log_queue.put((name, err_msg, "red"))
                            # Show error popup on main thread
                            self.after(
                                0,
                                lambda: messagebox.showerror(
                                    "Action Failed",
                                    f"Command failed:\n{cmd}\n\nSee logs for details.",
                                ),
                            )
                            return

                    except Exception as e:
                        mgr.log_queue.put((name, f"Action error: {e}", "red"))
                        self.after(
                            0, lambda: messagebox.showerror("Action Error", str(e))
                        )
                        return

                    # After command, do we restart?
                    if action_config.get("restart", False):
                        mgr.start()

                elif "arg" in action_config:
                    # Legacy args mode
                    mgr.start([action_config["arg"]])
            except Exception as e:
                print(f"Critical error in action thread: {e}")

        threading.Thread(target=_action_thread).start()

    def kill_all_orphans(self):
        # First stop managed
        self.stop_all()
        # Then try to kill by ports/names (Primitive implementation)
        # In a real scenario we'd use psutil, but here we invoke taskkill for known executables or ports
        # Since we don't have psutil, let's just run generic taskkills relevant to our stack
        threading.Thread(target=self._force_kill_task).start()

    def _force_kill_task(self):
        self.log_queue.put(
            ("SYSTEM", "Attempting to kill orphaned processes...", "red")
        )
        # Kill python uvicorn, node, java (spring)
        # Be careful not to kill SELF if we are python (manager)
        # We can try killing by port
        commands = [
            "taskkill /F /IM node.exe /T",
            "taskkill /F /IM java.exe /T",
            # uvicorn implies python, risky to kill all python.
            # Better to find by port if possible, but netstat parsing is hard in pure python without psutil.
            # We'll skip blind python kill to avoid suicide.
        ]
        for cmd in commands:
            try:
                subprocess.run(
                    cmd,
                    shell=True,
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except:
                pass
        self.log_queue.put(("SYSTEM", "Kill command sent.", "red"))

    def clear_current_log(self):
        self.clear_service_log(self.current_service)

    def clear_service_log(self, name):
        self.log_buffers[name] = []
        if self.current_service == name:
            self.show_service(name)  # Refresh UI if viewing

    def _init_managers(self):
        for conf in SERVICES_CONFIG:
            mgr = ServiceManager(
                conf, self.log_queue, self.update_status_ui, self.clear_service_log
            )
            self.managers[conf.name] = mgr

    def _process_queue(self):
        try:
            while True:
                # Get all available messages
                svc_name, msg, color = self.log_queue.get_nowait()

                # Format: [SERVICE] message
                full_line = f"[{svc_name}] {msg}\n"

                # Store in memory buffer
                if svc_name == "SYSTEM":
                    # Broadcast to all buffers or just show in current?
                    # Let's just append to current view for visibility + all buffers
                    for k in self.log_buffers:
                        self.log_buffers[k].append(full_line)
                    self.append_log(full_line, color)
                else:
                    self.log_buffers[svc_name].append(full_line)
                    if len(self.log_buffers[svc_name]) > 1000:
                        self.log_buffers[svc_name].pop(0)

                    # If currently viewing this service
                    if svc_name == self.current_service:
                        self.append_log(full_line, color)

        except queue.Empty:
            pass

        self.after(100, self._process_queue)

    def append_log(self, text, tag="black"):
        self.log_area.configure(state="normal")
        self.log_area.insert("end", text, tag)
        self.log_area.see("end")
        self.log_area.configure(state="disabled")

    def show_service(self, name):
        self.current_service = name
        self.lbl_current.config(text=f"Logs: {name}")

        self.log_area.configure(state="normal")
        self.log_area.delete("1.0", "end")
        for line in self.log_buffers[name]:
            # Simple parsing to re-apply color if needed, or just default
            self.log_area.insert("end", line)
        self.log_area.see("end")
        self.log_area.configure(state="disabled")

    def update_status_ui(self, name, is_running):
        self.after(0, lambda: self._update_card(name, is_running))

    def _update_card(self, name, is_running):
        widgets = self.service_widgets[name]
        if is_running:
            widgets["status"].config(text="RUNNING", foreground="green")
            widgets["btn"].config(text="■ Stop")
        else:
            widgets["status"].config(text="STOPPED", foreground="red")
            widgets["btn"].config(text="▶ Run")

    # Actions
    def start_service(self, name):
        threading.Thread(target=self.managers[name].start).start()

    def stop_service(self, name):
        threading.Thread(target=self.managers[name].stop).start()

    def restart_service(self, name):
        def _restart():
            self.managers[name].stop()
            self.managers[name].start()

        threading.Thread(target=_restart).start()

    def start_all(self):
        for name in self.managers:
            self.start_service(name)

    def stop_all(self):
        for name in self.managers:
            self.stop_service(name)

    def destroy(self):
        self.stop_all()
        super().destroy()


if __name__ == "__main__":
    app = ServiceApp()
    app.mainloop()
