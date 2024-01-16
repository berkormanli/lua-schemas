# lua-schemas

## Overview

lua-schemas, a powerful schema validation library for Lua! This library draws inspiration from the TypeScript `zod` library, allowing users to define schemas and validate data against those schemas with ease.

## Features

- **Schema Definition**: Create structured schemas using Lua to define the expected structure of your data.
- **Validation**: Validate input data against defined schemas, ensuring it meets specified criteria.
- **Data Transformation**: Convert and transform data based on defined schemas.

## Getting Started

1. **Installation**:

   ```lua
   local l = require("lua-schemas")
   ```

2. **Defining a Schema**:

   ```lua
   local userSchema = l.object({
     id = l.number(),
     username = l.string(),
     email = l.string().email(),
   })
   ```

3. **Validation**:

   ```lua
   local userData = {
     id = 1,
     username = "john_doe",
     email = "john@example.com",
   }

   local validationResult = userSchema:validate(userData)

   if validationResult then
     print("Data is valid!")
   else
     print("Validation errors:", validationResult)
   ```

## Examples

### Basic Schema:

```lua
local personSchema = SchemaLib.object({
  name = SchemaLib.string(),
  age = SchemaLib.number().positive(),
})
```

### Complex Schema with Nested Objects:

```lua
local addressSchema = SchemaLib.object({
  street = SchemaLib.string(),
  city = SchemaLib.string(),
  zipCode = SchemaLib.string().pattern("^%d%d%d%d%d$"),
})

local userSchema = SchemaLib.object({
  name = SchemaLib.string(),
  age = SchemaLib.number().positive(),
  address = addressSchema,
})
```

## Contributions

Contributions are welcome! If you find a bug or have an enhancement, feel free to open an issue or submit a pull request.

## License

This library is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the TypeScript `zod` library.
- Special thanks to the Lua community for their support and feedback.

Happy validating with LuaSchemaLib!