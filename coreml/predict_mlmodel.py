import coremltools as ct
import numpy as np

# Load the model
model = ct.models.MLModel('model.mlmodel')

# Make predictions
predictions = model.predict({'input': np.array([1.0, 2.0, 3.0, 4.0]).astype('float32')})
print(predictions)