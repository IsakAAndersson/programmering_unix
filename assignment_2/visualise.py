import matplotlib.pyplot as plt
import numpy as np

# Läs in data (tre kolumner: x, y, class)
data = np.loadtxt("kmeans-output.txt")

x = data[:, 0]
y = data[:, 1]
labels = data[:, 2].astype(int)

# Rita scatter plot med färger baserat på kluster (kolumn 3)
plt.figure(figsize=(8, 6))
scatter = plt.scatter(x, y, c=labels, cmap='tab10', s=40)

plt.title("2D scatter plot by cluster")
plt.xlabel("X coordinate")
plt.ylabel("Y coordinate")

# Lägg till färglegend
legend1 = plt.legend(*scatter.legend_elements(), title="Cluster")
plt.gca().add_artist(legend1)

plt.grid(True)
plt.tight_layout()

# Spara först, visa sen
plt.savefig("scatter_plot.png")
