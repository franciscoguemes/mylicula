#!/usr/bin/env python3
""" This is a docstring that explains what the script/module/function/class does and it used by convention in Python (PEP 257)
for better code documentation. Some IDEs show it on mouse hovering on the function. You can show this docstring by importing
module and using the built in function `help`
```
import my_module
help(my_module)
```
"""
####################################################################################################
#Script Name	: yourscriptname.py                                                                                             
#Description	: Here it goes your description
#                                                                                 
#Args           : 
#Author       	: Francisco Güemes                                                
#Email         	: francisco@franciscoguemes.com                                           
#See also	    : 
#
####################################################################################################

# Some common Python imports add/delete conveniently
import sys  
import re   


# Constants definitions
MY_CONSTANT="Your constant value"


if __name__ == "__main__":
    # Your script starts here...
    some_error_happened=False

    if some_error_happened:
        exit(1) # Abnormal execution so return some error code to the OS

    #By default Python returns 0 to the OS so no exit(0) statement is needed

