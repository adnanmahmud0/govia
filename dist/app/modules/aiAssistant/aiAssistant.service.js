"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiAssistantService = void 0;
const openai_1 = __importDefault(require("openai"));
const config_1 = __importDefault(require("../../../config"));
const ApiError_1 = __importDefault(require("../../../errors/ApiError"));
const http_status_codes_1 = require("http-status-codes");
// Initialize the OpenAI client pointing to the provider URL (OpenRouter or OpenAI)
const openai = new openai_1.default({
    apiKey: config_1.default.ai.apiKey,
    baseURL: config_1.default.ai.baseUrl,
});
const generateResponse = (prompt_1, ...args_1) => __awaiter(void 0, [prompt_1, ...args_1], void 0, function* (prompt, history = []) {
    var _a, _b;
    if (!config_1.default.ai.apiKey) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, 'AI API key is not configured');
    }
    const messages = [...history, { role: 'user', content: prompt }];
    try {
        const response = yield openai.chat.completions.create({
            model: config_1.default.ai.modelName,
            messages: messages,
        });
        return {
            message: ((_b = (_a = response.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content) || '',
            model: response.model,
            usage: response.usage,
        };
    }
    catch (error) {
        console.error('AI Assistant Error:', error);
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, `Failed to generate AI response: ${error.message}`);
    }
});
exports.AiAssistantService = {
    generateResponse,
};
