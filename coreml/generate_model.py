import pandas as pd 
import numpy as np
import pickle
import coremltools as ct

from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

df = pd.read_csv('./train_data.csv')

labels = np.unique(df['Location'])
encoder = LabelEncoder()
encoder.fit(labels)

x = df[['CAPSTONE_AP_1', 'CAPSTONE_AP_2', 'CAPSTONE_AP_3', 'CAPSTONE_AP_4']].to_numpy()
y = encoder.transform(df['Location'])

X_train, x_test, y_train, y_test = train_test_split(x, y, test_size = 0.2, random_state = 0)

classifier = KNeighborsClassifier(n_neighbors=3)
classifier.fit(X_train, y_train)
y_pred = classifier.predict(x_test)

print(classifier.score(x_test, y_test))

with open('model.pkl', 'wb') as f:
  pickle.dump(classifier, f)

with open('model.pkl', 'rb') as f:
  model = pickle.load(f)

coreml_model = ct.converters.sklearn.convert(model)
coreml_model.save('RSSIModel.mlmodel')
