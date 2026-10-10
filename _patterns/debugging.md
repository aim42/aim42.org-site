---
title: Debugging
phase: analyze
intent: Identify the source of an error (*bug*) or misbehavior by observing the flow of execution of a program in detail.
related: [root-cause-analysis]
status: complete
---

> **Tip:** Many software developers we met violated the basic rules of debugging. They worked in haste, took wrong assumptions, imagined-instead-of-read or simply hunted bugs at the wrong parts of the system.

## Description

Debuggers are well-known and important tools for most software developers. Yet finding bugs is often more difficult than expected - despite powerful tool support.

Approach the search for bugs, errors in the following order:

1.  Get a clear and precise **description** of the error, the detailed wording of all error messages, log messages, stacktraces or similar information.
2.  Know the **context** of the error: the exact version of the system, the operating system, involved middleware, hardware settings and so on. Have knowledge of the input data which leads to the error.
3.  **Minimize external disturbance** while searching for errors, you need to concentrate and observe details. Shut off chat and twitter clients, notifications and your phone. Send away your boss to an important management mission and lean back to reflect the error. Perhaps a colleague can support you.
4.  **Reproduce the error** in the live system. Don’t rely on the assumption you can reproduce it - make sure you can reliably *really* reproduce it.
5.  **Obtain the exact version** of all required source code and all involved data.
6.  **Reproduce the error in development environment**: This ensures your development environment is consistent to the live system.
7.  **Rephrase your error assumption into a question**: Distinguish symptoms from the cause of the error by asking "why?" a few times.
8.  **Identify the building blocks** which are involved in the error path.
9.  **Understand the error scenario**: You need to know the business or technical scenario (aka the process or activity flow) of the error: Which steps within the system or its external interfaces precede the error? This step is an example of [View-Based Understanding](/patterns/view-based-understanding/).
    1.  Make this scenario **explicit** - draw or scribble a diagram. See the diagram "Divide and conquer" below as an example. Here the error arises in building block 1. You suppose the processing within the system is spanned by the blue marked data path in which the building blocks 2 to 6 are involved. Cut the path in half and check your assumption at the transition of one half to the other (here between building block 4 and 3). If no error is observable here then the error occurs after the considered transition. Otherwise you have to look for the error before the transition.
        
        ![Divide and conquer debugging tactics](/images/patterns/debugging-divide-and-conquer.jpg)

    2.  **Plan your debugging strategy**: Think of the expected outcome of every part of your scenario.
    3.  If you know you’re traveling to Pisa (Italy), you won’t confuse the Leaning Tower with an error.

10. **Look, don’t imagine**: Sherlock Holmes, the successful detective has formulated the golden rule of debugging: "*It’s a capital mistake to theorize before one has data*". Instrument the system or use step debugging. Look *exactly* what the messages are, read carefully.
11. **Change only one thing at a time** and test if the error disappears: Aim for errors with a sniper rifle, not with a shotgun.
12. Apply the **4-Eye-Principle**: Describe the problem and your state of debugging to somebody else. Especially clarify all your assumptions.

## Experiences

If locating errors takes very long, you’re probably facing one of the following issues:

* You suffer from any assumption that’s currently not valid.
* You *think* something instead of *observing* it - you let your mind deceive your eyes or ears.
* You ignore the context: you test a wrong version, with wrong data or a wrong operating system.

## Applicability

* Whenever a bug or misbehavior of a program is reported, debugging can help to identify its root cause.
* Debugging can help to understand a system by making its inner working explicit.
