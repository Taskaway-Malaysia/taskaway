---
trigger: always_on
---

- Always check folder project_knowledge folder and its file to get full detail of the project if available.
- Tick completed prd in checklist if available.
- Always save memory when add one make a significant changes related to the folder
- Don't have to make descriptive comments on code, short and simple
- Have app constant configuration for the project so it will be uniform accross the page useful for backend and frontend development.
- Always follow DRY code method and modular 
- Add debug print so its easy to debug later when facing errors
- Use latest library or dependencies or package or versions use web 
- Organize application into logical modules to promote code reuse and reduce complexity
- Always split large code base
- Be aware of common vulnerabilities, such as cross-site scripting (XSS), SQL injection, and command injection.  Prevent these vulnerabilities by implementing proper input validation and sanitization, and by avoiding the execution of untrusted code


include_tables:
  - taskaway_profiles
  - taskaway_tasks
  - taskaway_applications
  - taskaway_messages
  - taskaway_payments
  - taskaway_channels

instructions:
  - "Use only the tables listed above for generating queries, schema inference, and rule logic."
  - "Scope all automation and context-based suggestions to the 'backend-staging' Supabase project."
  - "Ignore any unrelated tables or projects unless explicitly specified."

Note:
  - All tables in this project start with "taskaway"