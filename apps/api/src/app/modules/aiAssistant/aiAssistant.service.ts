import OpenAI from 'openai';
import config from '../../../config';
import ApiError from '../../../errors/ApiError';
import { StatusCodes } from 'http-status-codes';
import fs from 'fs';
import path from 'path';
import { AiChat } from './aiChat.model';
import { Types } from 'mongoose';

// Initialize the OpenAI client pointing to the provider URL (OpenRouter or OpenAI)
const openai = new OpenAI({
  apiKey: config.ai.apiKey,
  baseURL: config.ai.baseUrl,
});

type Message = {
  role: 'system' | 'user' | 'assistant';
  content: string;
};

type LawSection = {
  section?: string;
  raws?: string[];
};

type LawChapter = {
  sections?: LawSection[];
};

type LawTitle = {
  chapters?: LawChapter[];
};

// Load US Law data into memory
let usLawData: LawTitle[] = [];
try {
  const possiblePaths = [
    path.join(process.cwd(), 'ai-data', 'uslaw.json'),
    path.join(process.cwd(), '..', '..', 'ai-data', 'uslaw.json'),
    path.resolve(__dirname, '../../../../ai-data/uslaw.json'),
  ];
  const dataPath = possiblePaths.find(p => fs.existsSync(p));
  if (dataPath) {
    const rawData = fs.readFileSync(dataPath, 'utf-8');
    usLawData = JSON.parse(rawData);
    console.log(`Loaded ${usLawData.length} top-level items from uslaw.json at ${dataPath}`);
  } else {
    console.warn('uslaw.json not found in candidate paths');
  }
} catch (error) {
  console.error('Failed to load uslaw.json', error);
}

// Simple keyword search function to extract context
const searchLawContext = (prompt: string): string => {
  if (usLawData.length === 0) return '';
  const keywords = prompt.toLowerCase().split(' ').filter((w) => w.length > 3);
  if (keywords.length === 0) return '';

  const matches: string[] = [];

  for (const title of usLawData) {
    if (matches.length >= 3) break;
    if (title.chapters) {
      for (const chapter of title.chapters) {
        if (matches.length >= 3) break;
        if (chapter.sections) {
          for (const section of chapter.sections) {
            const sectionText = (section.section || '') + ' ' + (section.raws?.join(' ') || '');
            const sectionLower = sectionText.toLowerCase();
            
            // If the section matches at least one keyword, include it
            const isMatch = keywords.some((kw) => sectionLower.includes(kw));
            if (isMatch) {
              matches.push(sectionText.substring(0, 500) + '...');
              if (matches.length >= 3) break;
            }
          }
        }
      }
    }
  }

  return matches.length > 0 ? `\n\nRelevant US Law Context:\n${matches.join('\n\n')}` : '';
};

const generateResponse = async (userId: string, prompt: string, chatId?: string, providedHistory: Message[] = []) => {
  if (!config.ai.apiKey) {
    throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, 'AI API key is not configured');
  }

  let chat;
  let history: Message[] = [];

  if (chatId) {
    chat = await AiChat.findOne({ _id: chatId, userId });
    if (!chat) {
      throw new ApiError(StatusCodes.NOT_FOUND, 'Chat not found');
    }
    history = chat.messages.map(m => ({ role: m.role, content: m.content }));
  } else {
    history = providedHistory;
  }

  // Generate context from US Law JSON
  const lawContext = searchLawContext(prompt);
  
  const systemPrompt = `You are a specialized US Law Assistant. Only answer questions related to US law. Use the provided context to help answer if relevant. If the user asks a question outside of US law, politely decline to answer.${lawContext}`;

  const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
    { role: 'system', content: systemPrompt },
    ...(history.map(h => ({ role: h.role, content: h.content })) as OpenAI.Chat.Completions.ChatCompletionMessageParam[]),
    { role: 'user', content: prompt }
  ];

  try {
    const response = await openai.chat.completions.create({
      model: config.ai.modelName as string,
      messages,
    });

    const aiMessageContent = response.choices[0]?.message?.content || '';

    // Save to DB
    const userMsg = { role: 'user' as const, content: prompt };
    const assistantMsg = { role: 'assistant' as const, content: aiMessageContent };

    if (chat) {
      chat.messages.push(userMsg, assistantMsg);
      await chat.save();
    } else {
      chat = await AiChat.create({
        userId: new Types.ObjectId(userId),
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
  } catch (error: unknown) {
    console.error('AI Assistant Error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    throw new ApiError(StatusCodes.INTERNAL_SERVER_ERROR, `Failed to generate AI response: ${errorMessage}`);
  }
};

const getChatList = async (userId: string) => {
  const chats = await AiChat.find({ userId })
    .select('_id title createdAt updatedAt')
    .sort({ updatedAt: -1 });
  return chats;
};

const getChatHistory = async (userId: string, chatId: string) => {
  const chat = await AiChat.findOne({ _id: chatId, userId });
  if (!chat) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Chat not found');
  }
  return chat;
};

export const AiAssistantService = {
  generateResponse,
  getChatList,
  getChatHistory,
};
