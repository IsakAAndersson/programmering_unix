import matplotlib.pyplot as plt
import numpy as np

# Läs in data (tre kolumner: x, y, class)
data = np.loadtxt("kmeans-output.txt")

x = data[:, 0]
y = data[:, 1]
labels = data[:, 2]

# Rita scatter plot – olika färger för varje klass
plt.figure(figsize=(8, 6))
for cls in np.unique(labels):
    plt.scatter(x[labels == cls], y[labels == cls], label=f'Class {int(cls)}', s=40)

plt.title("2D scatter plot by class")
plt.xlabel("X coordinate")
plt.ylabel("Y coordinate")
plt.legend()
plt.grid(True)
plt.show()
plt.savefig("scatter_plot.png")
