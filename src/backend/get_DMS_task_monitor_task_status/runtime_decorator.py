import time
from datetime import datetime

def runtime_log(func):
    """Um decorator que imprime o tempo de execução de uma função."""
    def wrapper(*args, **kwargs):
        print(f"--- Start: {func.__name__} ---")
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"--- End: {func.__name__} -> {(end_time - start_time):.4f}s ---")
        return result
    return wrapper