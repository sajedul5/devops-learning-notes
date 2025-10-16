# print("Hello Python")

# var = "shakil"
# var2 = 'Shakil'
# number = 420
# price = 56.03
# is_employee= True
# is_student= False
# result = None
# print(var)
# print(number)
# print(price)
# print(is_employee)
# print(is_student)

# print("--------------------------")

# print(var, type(var))
# print(number, type(number))
# print(price, type(price))
# print(is_employee , type(is_employee) )
# print(result , type (result))



import requests
response = requests.get("https://api.github.com")
print(response.json())


