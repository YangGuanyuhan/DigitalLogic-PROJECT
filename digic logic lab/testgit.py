import numpy as np

import matplotlib.pyplot as plt

# Generate data for a normal distribution
mu, sigma = 0, 0.1  # mean and standard deviation
s = np.random.normal(mu, sigma, 1000)

# Create the histogram
count, bins, ignored = plt.hist(s, 30, density=True, alpha=0.6, color='g')

# Plot the normal distribution curve
plt.plot(bins, 1/(sigma * np.sqrt(2 * np.pi)) * np.exp( - (bins - mu)**2 / (2 * sigma**2) ), linewidth=2, color='r')
plt.title('Normal Distribution')
plt.xlabel('Value')
plt.ylabel('Frequency')

# Show the plot
plt.show()