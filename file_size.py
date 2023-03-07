import os
import sys

def get_size(file_name):
    file_stats = os.stat(file_name)
    size  = file_stats.st_size / (1024)
    return size #in KB

size = get_size(file_name)

