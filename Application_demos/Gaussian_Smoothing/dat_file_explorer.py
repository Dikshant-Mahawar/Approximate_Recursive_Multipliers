import pandas as pd 
import os

# THis is Local directory of the PROJECT and not the current directory of pytho file
current_working_dir = os.getcwd()
print(current_working_dir)


# THis works after I copy this file to Direcoty of the VSC project
with open('./input_to_multiply.dat', 'r') as f:
    print(len(f.readlines()))       # 8_619_075



with open('./output_from_multiplier.dat', 'r') as f:
    print(len(f.readlines()))



df = pd.read_csv('./input_to_multiply.dat', sep='\s+', header=None)
df1 = pd.read_csv('./output_from_multiplier.dat', sep='\s+', header=None)

print("Number of lines:", len(df))
print("Number of lines:", len(df1))

# Distribution of the first number
print("Distribution of the first number:")
print(df[0].describe())
df[0].hist()

# Distribution of the second number
print("Distribution of the second number:")
print(df[1].describe())
df[1].hist()