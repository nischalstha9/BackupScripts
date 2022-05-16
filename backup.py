#!/usr/bin/python3

from parso import parse


project_path = "/home/nischal/dev/OnlineDonationPlatform"
env_file_name = ".env"
# project_path = input("Enter project path: \n")
# env_file_name = input("Enter env file name: \n")
# if env_file_name == "":
#     env_file_name=".env"


def parse_env(envFile):
    with open(envFile, "r") as env:
        print(env.read())
        return env.read()

env = project_path+"/"+ env_file_name

text = parse_env(env)
text = text.split("=")
for 

# print(text)