+++
date = 2020-06-01
slug = "a-philosophy-of-software-design-note"
title = "软件设计哲学(NOTE)"

[taxonomies]
tags = [ "engineering" ]
+++

# RED FLAGS
## Shallow Module
A shallow module is one whose interface is complicated relative to the functionality it provides. Shallow modules don’t help much in the
battle against complexity, because the benefit they provide (not having to learn about how they work internally) is negated by the cost
of learning and using their interfaces. Small modules tend to be shallow.
## Information Leakage
Information leakage occurs when the **same knownledge is used in multiple places**, such as two different classed that both understand the
format of a particular type of file.
## Temporal Decomposition
In temporal decomposition, execution order is reflected in the code structure: operations that happen at different times are in different
methods or classes. If the same knowledge is used at different points in execution, it get encoded in multiple places, resulting in
information leakage.
## Overexposure
If the API for a commonly used feature forces users to learn about other features that are rarely used, this increases the cognitive load on users who don’t need the rarely used features.
## Pass-Through Method
A pass-through method is one that does nothing except pass its arguments to another method, usually with the same API as the pass-through
method. This typically indicates that there is not a clean division of respoinsibility between the classes.
## Repetition
If the same piece of code (or code that is almost the same) appears over and over again, that’s a red flag that you haven’t found the right abstractions.
## Special-General Mixture
This red flag occurs when a general-purpose mechanism also contains code specialized for a particular use of that mechanism. This makes the mechanism more complicated and creates information leakage between the 80 mechanism and the particular use case: future modifications to the use case are likely to require changes to the underlying mechanism as well.
## Conjoined Methods
It should be possible to understand each method independently. If you can’t understand the implementation of one method without also understanding the implementation of another, that’s a red flag.
## Comment Repeats Code
Red Flag: Comment Repeats Code If the information in a comment is already obvious from the code next to the comment, then the comment isn’t helpful. One example of this is when the comment uses the same words that make up the name of the thing it is describing.
## Implementation Documentation Contaminates Interface
This red flag occurs when interface documentation, such as that for a method, describes implementation details that aren’t needed in order to use the thing being documented.
## Vague Name
If a variable or method name is broad enough to refer to many different things, then it doesn’t convey much information to the developer and the underlying entity is more likely to be misused.
## Hard to Pick Name
If it’s hard to find a simple name for a variable or method that creates a clear image of the underlying object, that’s a hint that the underlying object may not have a clean design.
## Hard to Describe
The comment that describes a method or variable should be simple and yet complete. If you find it difficult to write such a comment, that’s an indicator that there may be a problem with the design of the thing you are describing.

# EXCERPT
### Definition
**Complexity** is anything related to the structure of a software system that makes it hard to understand and modify the system.
$$ C = \sum\_{p}c\_pt\_p $$
The overall complexity of a system $(C)$ is determined by the complexity of each part $p(c\_p)$ weighted by the faction of time
developers spend working on the part $(t\_p)$.

### Symptoms
- **Change amplification**: The first symptom of complexity is that a seemingly simple change requires code modifications in
many different places.
- **Cognitive load**: The second symptom of complexity is cognitive load, which refers to how much a developer needs to know
in order to complete a task.
- **Unknown unknowns**: The third symptom of complexity is that it is not obvious which pieces of code must be modified to
complete a task, or what information a developer must have to carry out the task successfully.

## Modules
- In this world, the complexity of a system would be the complexity of its worst module.
- The interface describes *what* the module does but not *how* it does it.
- The best modules are those whose interfaces are much simpler than their implementations.
- An **abstraction** is a simplified view of an entity, which omits unimportant details.
- Interface:
  - The interface to a module contains two kinds of information: **formal** and **informal**.
    - The formal parts of an interface are specified explicitly in the code, and some of these can be checked for correctness
    by the programming language.
    - The informal parts of an interface includes its high-level behavior, such as the fact that a function deletes the file named by
    one of its arguments.
  - In modular programming, each module provides an abstraction in form of its interface. The interface presents a simplified view of the module’s functionality; the details of the implementation are unimportant from the standpoint of the module’s abstraction, so they are omitted from the interface. **A detail can only be omiited from an abstraction if it is unimportant.**
- The best modules are those that provide powerful functionality yet have simple interfaces: they have a lot of functionality hidden behind
a simple interface. A deep module is a good abstraction because only a small fraction of its internal complexity is visible to its users.
- Classitis may result in classes that are individually simple, but it increases the complexity of the overall system. Small classes don’t contribute much functionality, so there have to be a lot of them, each with its own interface. These interfaces accumulate to create tremendous complexity at the system level.
- Provide choice is good, but **interfaces should be designed to make the common case as simple as possible**. If an interface has many
features, but most developers only need to be aware of a few of them, the effective complexity of that interface is just the complexity
of the commonly used features.
- The most important (and perhaps surprising) benefit of the general- purpose approach is that it results in simpler and deeper interfaces than a special-purpose approach. The general-purpose approach can also save you time in the future, if you reuse the class for other purposes. However, even if the module is only used for its original purpose, the general-purpose approach is still better because of its simplicity.
- Questions to ask yourself
  - What is the simplest interface that will cover all my current needs?
  - In how many situations will this method be used?
  - Is this API easy to use for my current needs?
- Decorators
  - A decorator object takes an existing object and extends its functionality; it provides an API similar or identical to the underlying object, and its methods invoke the methods of the underlying object.
  - Before creating a decorator class, consider alternatives such as the following:
    - Could you add the new functionality directly to the underlying class, rather than creating a decorator class?
    - If the new functionality is specialized for a particular use case, would it make sense to merge it with the use case, rather than creating a separate class?
    - Could you merge the new functionality with an existing decorator, rather than creating a new decorator?
    - Finally, ask yourself whether the new functionality really needs to wrap the existing functionality: could you implement it as a stand-alone class that is independent of the base class?

### Together vs Apart
- Bring together if information is shared
- Bring together if it will simplify the interface
- Bring together to eliminate duplication

### Comments
- Documentation also plays an important role in abstraction; without comments, you can’t hide complexity.
- If users must read the code of a method in order to use it, then there is no abstraction: all of the complexity of the method is exposed.
- Many of the most important comments are those related to abstractions, such as the top-level documentation for classes and methods.
- **The overall idea behind comments is to capture information that was in the mind of the designer but couldn’t be represented in the code.**
- **Comments should describe things that aren’t obvious from the code.**
- One of the most important reasons for comments is abstractions, which include a lot of information that isn’t obvious from the code.
- Developers should be able to understand the abstraction provided by a module without reading any code other than its externally visible declarations.
- Comments categories:
  - **Interface**: a comment block that immediately precedes the declaration of a module such as a class, data structure, function, or method. The comment describe’s the module’s interface.
  - **Data structure member**: a comment next to the declaration of a field in a data structure, such as an instance variable or static variable for a class.
  - **Implementation comment**: a comment inside the code of a method or function, which describes how the code works internally.
  - **Cross-module comment**: a comment describing dependencies that cross module boundaries.
- After you have written a comment, ask yourself the following question: could someone who has never seen the code write the comment just by looking at the code next to the comment? If the answer is yes, as in the examples above, then the comment doesn’t make the code any easier to understand. Comments like these are why some people think that comments are worthless.
- Comments augment the code by providing information at a different level of detail.
  - Precision is most useful when commenting variable declarations such as class instance variables, method arguments, and return values. The name and type in a variable declaration are typically not very precise. Comments can fill in missing details such as:
    - What are the units for this variable?
    - Are the boundary conditions inclusive or exclusive?
    - If a null value is permitted, what does it imply?
    - If a variable refers to a resource that must eventually be freed or closed, who is responsible for freeing or closing it?
    - Are there certain properties that are always true for the variable (invariants), such as “this list always contains at least one entry”?
  - When documenting a variable, think nouns, not verbs. In other words, focus on what the variable represents, not how it is manipulated.
- **The best time to write comments is at the beginning of the process, as you write the code**. Writing the comments first makes documentation part of the design process. Not only does this produce better documentation, but it also produces better designs and it makes the process of writing documentation more enjoyable.
#### Interface Comments
The interface comment for a method includes both higher-level information for abstraction and lower-level details for precision:
- The comment usually starts with a sentence or two describing the behavior of the method as perceived by callers; this is the higher-level abstraction.
- The comment must describe each argument and the return value (if any).
  These comments must be very precise, and must describe any constraints on argument values as well as dependencies between arguments.
- If the method has any side effects, these must be documented in the interface comment. A side effect is any consequence of the method that affects the future behavior of the system but is not part of the result. For example, if the method adds a value to an internal data structure, which can be retrieved by future method calls, this is a side effect; writing to the file system is also a side effect.
- A method’s interface comment must describe any exceptions that can emanate from the method.
- If there are any preconditions that must be satisfied before a method is invoked, these must be described (perhaps some other method must be invoked first; for a binary search method, the list being searched must be sorted). It is a good idea to minimize preconditions, but any that remain must be documented.
#### Implementation Comments
The main goal of implementation comments is to help readers understand *what* the code is doing (not how it does it).

