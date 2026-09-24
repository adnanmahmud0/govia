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

const STOP_WORDS = new Set([
  'what', 'when', 'where', 'which', 'with', 'that', 'this', 'have',
  'from', 'they', 'will', 'would', 'could', 'should', 'about', 'there',
  'their', 'does', 'done', 'help', 'please', 'know', 'tell', 'make',
  'just', 'some', 'than', 'them', 'then', 'into', 'only', 'also',
  'more', 'very', 'here', 'your', 'ours', 'mine', 'need', 'give',
  'want', 'like', 'good', 'time', 'take', 'come', 'find'
]);

// Keyword search function to extract meaningful legal context from uslaw.json
const searchLawContext = (prompt: string): string => {
  if (usLawData.length === 0) return '';
  
  // Extract meaningful legal tokens (filter out punctuation and common stop-words)
  const cleanTokens = prompt
    .toLowerCase()
    .replace(/[^a-z0-9 ]/g, ' ')
    .split(/\s+/)
    .filter((w) => w.length > 3 && !STOP_WORDS.has(w));

  if (cleanTokens.length === 0) return '';

  const matches: string[] = [];

  for (const title of usLawData) {
    if (matches.length >= 2) break;
    if (title.chapters) {
      for (const chapter of title.chapters) {
        if (matches.length >= 2) break;
        if (chapter.sections) {
          for (const section of chapter.sections) {
            const sectionText = (section.section || '') + ' ' + (section.raws?.join(' ') || '');
            const sectionLower = sectionText.toLowerCase();

            // Match if at least 2 keywords match or 1 highly specific keyword matches
            const matchCount = cleanTokens.filter((kw) => sectionLower.includes(kw)).length;
            if (matchCount >= 2 || (cleanTokens.length === 1 && matchCount >= 1)) {
              matches.push(sectionText.substring(0, 450) + '...');
              if (matches.length >= 2) break;
            }
          }
        }
      }
    }
  }

  return matches.length > 0 ? `\n\nRelevant Reference US Law Excerpt:\n${matches.join('\n\n')}` : '';
};

const getRoleInstruction = (role?: string): string => {
  const normalized = (role || 'CITIZEN').toUpperCase();
  switch (normalized) {
    case 'POLICE':
      return 'The user is a Law Enforcement Officer. Provide objective, precise procedural guidance regarding constitutional standards (4th Amendment searches/seizures, Terry stops, probable cause, Miranda requirements, warrant execution, and officer safety protocols).';
    case 'ATTORNEY':
      return 'The user is a Licensed Defense Attorney or Legal Counsel. Provide high-level legal analysis citing constitutional doctrines, statutory frameworks, evidentiary standards, and potential motion/defense strategies.';
    case 'MENTAL_HEALTH_PROFESSIONAL':
      return 'The user is a Mental Health Professional or Crisis Responder. Provide guidance on mental health emergency statutes, involuntary evaluation thresholds (such as 72-hour holds), patient privacy (HIPAA) exceptions during imminent harm, and legal agency coordination.';
    case 'BAIL_BONDSMAN':
      return 'The user is a Licensed Bail Bondsman. Provide guidance regarding surety bond statutes, indemnitor agreements, fugitive recovery regulations, court appearance compliance, and forfeiture procedures.';
    case 'CITIZEN':
    default:
      return 'The user is a US Citizen. Provide clear, empowering, step-by-step guidance on their constitutional rights during police interactions (traffic stops, questioning, search consent), 4th & 5th Amendment protections, how to request an attorney, and how bail bonds work.';
  }
};

const generateResponse = async (
  userId: string,
  prompt: string,
  chatId?: string,
  providedHistory: Message[] = [],
  userRole?: string
) => {
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
    history = chat.messages.map((m) => ({ role: m.role, content: m.content }));
  } else {
    history = providedHistory;
  }

  // Generate context from US Law JSON
  const lawContext = searchLawContext(prompt);
  const roleInstruction = getRoleInstruction(userRole);

  const systemPrompt = `You are GoVia AI Assistant, an expert US Law Copilot in the GoVia public safety ecosystem.
${roleInstruction}
Always provide a comprehensive, structured, and actionable answer directly addressing the user's question.
Use markdown formatting with bold headings and bullet points.
Explain relevant constitutional rights (such as 4th, 5th, and 6th Amendments) clearly and objectively.
Do NOT output classification tags, safety labels (such as "User Safety: safe"), or one-word replies. Always provide full, informative legal guidance.
If the user asks about matters completely unrelated to law, civil rights, police encounters, or legal procedures, politely explain that you specialize exclusively in US law and public safety.
At the end of your guidance, include a brief one-line note:
*Disclaimer: GoVia AI provides legal information and educational guidance, not formal attorney representation. Consult a licensed attorney for official legal counsel.*${lawContext}`;

  const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
    { role: 'system', content: systemPrompt },
    ...(history.map((h) => ({ role: h.role, content: h.content })) as OpenAI.Chat.Completions.ChatCompletionMessageParam[]),
    { role: 'user', content: prompt },
  ];

  try {
    const response = await openai.chat.completions.create({
      model: config.ai.modelName as string,
      messages,
      temperature: 0.5,
    });

    let aiMessageContent = response.choices[0]?.message?.content || '';

    // Guard against rare models returning only safety classifications
    if (aiMessageContent.toLowerCase().includes('user safety:') || aiMessageContent.trim().length < 40) {
      const retryResponse = await openai.chat.completions.create({
        model: config.ai.modelName as string,
        messages: [
          ...messages,
          { role: 'user', content: 'Please give a detailed, substantive explanation of my legal rights and steps to take.' }
        ],
        temperature: 0.7,
      });
      const retryContent = retryResponse.choices[0]?.message?.content;
      if (retryContent && retryContent.trim().length > 40) {
        aiMessageContent = retryContent;
      }
    }

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
        messages: [...history, userMsg, assistantMsg],
      });
    }

    return {
      chatId: chat._id,
      title: chat.title,
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

const deleteChat = async (userId: string, chatId: string) => {
  const result = await AiChat.findOneAndDelete({ _id: chatId, userId });
  if (!result) {
    throw new ApiError(StatusCodes.NOT_FOUND, 'Chat not found');
  }
  return result;
};

const clearAllChats = async (userId: string) => {
  const result = await AiChat.deleteMany({ userId });
  return result;
};

export const AiAssistantService = {
  generateResponse,
  getChatList,
  getChatHistory,
  deleteChat,
  clearAllChats,
};

