"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiAssistantValidation = void 0;
const zod_1 = require("zod");
const generateResponseZodSchema = zod_1.z.object({
    body: zod_1.z.object({
        chatId: zod_1.z.string().optional(),
        prompt: zod_1.z.string({
            required_error: 'Prompt is required',
        }),
        history: zod_1.z
            .array(zod_1.z.object({
            role: zod_1.z.enum(['system', 'user', 'assistant']),
            content: zod_1.z.string(),
        }))
            .optional(),
    }),
});
exports.AiAssistantValidation = {
    generateResponseZodSchema,
};
