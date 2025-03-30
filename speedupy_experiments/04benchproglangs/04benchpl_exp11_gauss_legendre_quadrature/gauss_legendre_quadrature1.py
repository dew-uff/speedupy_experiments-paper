import numpy as np
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent / 'speedupy'))
import time
from speedupy.speedupy import initialize_speedupy, deterministic

@deterministic
def integrand(t):
    return np.exp(t)

@deterministic
def compute_quadrature(n):
    """
      Perform the Gauss-Legendre Quadrature at the prescribed order n
    """
    a = -3.0
    b = 3.0
    x, w = np.polynomial.legendre.leggauss(n)
    t = 0.5 * (x + 1) * (b - a) + a
    return sum(w * integrand(t)) * 0.5 * (b - a)

@initialize_speedupy
def main(order):
    for i in range(100, order + 1, 100):
        compute_quadrature(i)
if __name__ == '__main__':
    order = int(sys.argv[1])
    dti = time.perf_counter()
    main(order)
    print(time.perf_counter() - dti)