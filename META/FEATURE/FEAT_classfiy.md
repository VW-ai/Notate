# Feature Design
This document is th feature design of our text classficition, this file include the following:
1. Logic, and Components
2. Detailed Algorithm, init proposal

# Logic
# Workflow Logic
Our Classfication will take in process after our text comes in.
will work like the following:
1. Our detected text parsed in.
2. We uses an local model to create an embedding for the text.
( We have had existing embedding created based off of two groups of texts: TODO, and random thoughts)
3. We will use an `algorithm`, which uses the input embedding and existing to do some sort of classification.