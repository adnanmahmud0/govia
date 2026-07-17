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
exports.emailHelper = void 0;
const nodemailer_1 = __importDefault(require("nodemailer"));
const config_1 = __importDefault(require("../config"));
const debug_1 = require("../shared/debug");
const createConfiguredTransporter = () => __awaiter(void 0, void 0, void 0, function* () {
    var _a;
    const hasSmtpConfig = !!config_1.default.email.host && !!config_1.default.email.user && !!config_1.default.email.pass;
    if (hasSmtpConfig) {
        return nodemailer_1.default.createTransport({
            host: config_1.default.email.host,
            port: Number((_a = config_1.default.email.port) !== null && _a !== void 0 ? _a : 587),
            secure: false,
            auth: {
                user: config_1.default.email.user,
                pass: config_1.default.email.pass,
            },
        });
    }
    if (process.env.NODE_ENV !== 'production') {
        const testAccount = yield nodemailer_1.default.createTestAccount();
        return nodemailer_1.default.createTransport({
            host: 'smtp.ethereal.email',
            port: 587,
            secure: false,
            auth: {
                user: testAccount.user,
                pass: testAccount.pass,
            },
        });
    }
    return null;
});
const sendEmail = (values) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const transporter = yield createConfiguredTransporter();
        if (!transporter) {
            (0, debug_1.debugError)('email.transport.missing_config');
            if (process.env.NODE_ENV !== 'production') {
                (0, debug_1.debug)('email.dev.dump', { to: values.to, subject: values.subject });
            }
            return;
        }
        const info = yield transporter.sendMail({
            from: config_1.default.email.from || 'no-reply@example.com',
            to: values.to,
            subject: values.subject,
            html: values.html,
        });
        const preview = nodemailer_1.default.getTestMessageUrl(info);
        if (preview) {
            (0, debug_1.debug)('email.preview', preview);
        }
    }
    catch (error) {
        (0, debug_1.debugError)('email.send.failed', error);
        if (process.env.NODE_ENV !== 'production') {
            (0, debug_1.debug)('email.dev.dump', { to: values.to, subject: values.subject });
        }
    }
});
exports.emailHelper = {
    sendEmail,
};
