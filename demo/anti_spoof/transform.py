# -*- coding: utf-8 -*-
# Transform functions từ Silent-Face-Anti-Spoofing (chỉ giữ những gì cần thiết)

import torch
import numpy as np


class Compose:
    """Compose nhiều transforms"""
    def __init__(self, transforms):
        self.transforms = transforms

    def __call__(self, img):
        for t in self.transforms:
            img = t(img)
        return img


class ToTensor:
    """Convert numpy array sang tensor"""
    def __call__(self, pic):
        if isinstance(pic, np.ndarray):
            # Handle 2D grayscale
            if pic.ndim == 2:
                pic = pic.reshape((pic.shape[0], pic.shape[1], 1))
            # HWC -> CHW
            img = torch.from_numpy(pic.transpose((2, 0, 1)))
            return img.float()
        raise TypeError(f'pic should be ndarray. Got {type(pic)}')
