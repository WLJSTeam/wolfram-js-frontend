# Objects
Simple objects implementation

## Instalation

```wolfram
PaletInstall["KirillBelov/Objects"]
```

## Import

```wolfram
Get["KirillBelov`Objects`"]
```

## Object

Instance of the `Object`:

```wolfram
object1 = Object[]
```

>**Object[**<img width="300" height="70" align="middle" src="https://user-images.githubusercontent.com/16749283/216984255-9fe5d45a-948a-4e59-b0be-392a1b5a9f81.png">**]**

## New type

Let's create a type with default parent type (Object), constructor (Identity) and fields ({}):

```wolfram
CreateType[Human]
```

>Human

New type inherited from Human:

```wolfram
CreateType[Student, Human]
```

And with special constructor

```wolfram
Student /: IdentifyFaculty[student_Student] := student["Faculty"] = "Math"

CreateType[MathStudent, Student, IdentifyFaculty]
```

>MathStudent

And with custom fields:

```wolfram
CreateType[PhDStudent, MathStudent, IdentifyFaculty, {Advisor, "ScientificWork", Articles -> {}}]
```

>PhDStudent
