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
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const aiChat_model_1 = require("./aiChat.model");
const mongoose_1 = require("mongoose");
// Initialize the OpenAI client pointing to the provider URL (OpenRouter or OpenAI)
const openai = new openai_1.default({
    apiKey: config_1.default.ai.apiKey,
    baseURL: config_1.default.ai.baseUrl,
});
// Load US Law data into memory
let usLawData = [];
try {
    const dataPath = path_1.default.join(process.cwd(), 'ai-data', 'uslaw.json');
    if (fs_1.default.existsSync(dataPath)) {
        const rawData = fs_1.default.readFileSync(dataPath, 'utf-8');
        usLawData = JSON.parse(rawData);
        console.log(`Loaded ${usLawData.length} top-level items from uslaw.json`);
    }
    else {
        console.warn('uslaw.json not found at', dataPath);
    }
}
catch (error) {
    console.error('Failed to load uslaw.json', error);
}
// Simple keyword search function to extract context
const searchLawContext = (prompt) => {
    var _a;
    if (usLawData.length === 0)
        return '';
    const keywords = prompt.toLowerCase().split(' ').filter((w) => w.length > 3);
    if (keywords.length === 0)
        return '';
    let matches = [];
    for (const title of usLawData) {
        if (matches.length >= 3)
            break;
        if (title.chapters) {
            for (const chapter of title.chapters) {
                if (matches.length >= 3)
                    break;
                if (chapter.sections) {
                    for (const section of chapter.sections) {
                        const sectionText = (section.section || '') + ' ' + (((_a = section.raws) === null || _a === void 0 ? void 0 : _a.join(' ')) || '');
                        const sectionLower = sectionText.toLowerCase();
                        // If the section matches at least one keyword, include it
                        const isMatch = keywords.some((kw) => sectionLower.includes(kw));
                        if (isMatch) {
                            matches.push(sectionText.substring(0, 500) + '...');
                            if (matches.length >= 3)
                                break;
                        }
                    }
                }
            }
        }
    }
    return matches.length > 0 ? `\n\nRelevant US Law Context:\n${matches.join('\n\n')}` : '';
};
const generateResponse = (userId_1, prompt_1, chatId_1, ...args_1) => __awaiter(void 0, [userId_1, prompt_1, chatId_1, ...args_1], void 0, function* (userId, prompt, chatId, providedHistory = []) {
    var _a, _b;
    if (!config_1.default.ai.apiKey) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, 'AI API key is not configured');
    }
    let chat;
    let history = [];
    if (chatId) {
        chat = yield aiChat_model_1.AiChat.findOne({ _id: chatId, userId });
        if (!chat) {
            throw new ApiError_1.default(http_status_codes_1.StatusCodes.NOT_FOUND, 'Chat not found');
        }
        history = chat.messages.map(m => ({ role: m.role, content: m.content }));
    }
    else {
        history = providedHistory;
    }
    // Generate context from US Law JSON
    const lawContext = searchLawContext(prompt);
    const systemPrompt = `You are a specialized US Law Assistant. Only answer questions related to US law. Use the provided context to help answer if relevant. If the user asks a question outside of US law, politely decline to answer.${lawContext}`;
    const messages = [
        { role: 'system', content: systemPrompt },
        ...history,
        { role: 'user', content: prompt }
    ];
    try {
        const response = yield openai.chat.completions.create({
            model: config_1.default.ai.modelName,
            messages: messages,
        });
        const aiMessageContent = ((_b = (_a = response.choices[0]) === null || _a === void 0 ? void 0 : _a.message) === null || _b === void 0 ? void 0 : _b.content) || '';
        // Save to DB
        const userMsg = { role: 'user', content: prompt };
        const assistantMsg = { role: 'assistant', content: aiMessageContent };
        if (chat) {
            chat.messages.push(userMsg, assistantMsg);
            yield chat.save();
        }
        else {
            chat = yield aiChat_model_1.AiChat.create({
                userId: new mongoose_1.Types.ObjectId(userId),
                title: prompt.substring(0, 50) + (prompt.length > 50 ? '...' : ''),
                messages: [...history, userMsg, assistantMsg]
            });
        }
        return {
            chatId: chat._id,
            message: aiMessageContent,
            model: response.model,
            usage: response.usage,
        };
    }
    catch (error) {
        console.error('AI Assistant Error:', error);
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.INTERNAL_SERVER_ERROR, `Failed to generate AI response: ${error.message}`);
    }
});
const getChatList = (userId) => __awaiter(void 0, void 0, void 0, function* () {
    const chats = yield aiChat_model_1.AiChat.find({ userId })
        .select('_id title createdAt updatedAt')
        .sort({ updatedAt: -1 });
    return chats;
});
const getChatHistory = (userId, chatId) => __awaiter(void 0, void 0, void 0, function* () {
    const chat = yield aiChat_model_1.AiChat.findOne({ _id: chatId, userId });
    if (!chat) {
        throw new ApiError_1.default(http_status_codes_1.StatusCodes.NOT_FOUND, 'Chat not found');
    }
    return chat;
});
exports.AiAssistantService = {
    generateResponse,
    getChatList,
    getChatHistory,
};
