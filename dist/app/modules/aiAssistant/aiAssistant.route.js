"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AiAssistantRoutes = void 0;
const express_1 = __importDefault(require("express"));
const aiAssistant_controller_1 = require("./aiAssistant.controller");
const validateRequest_1 = __importDefault(require("../../middlewares/validateRequest"));
const aiAssistant_validation_1 = require("./aiAssistant.validation");
const auth_1 = __importDefault(require("../../middlewares/auth"));
const user_1 = require("../../../enums/user");
const router = express_1.default.Router();
router.post('/', (0, auth_1.default)(user_1.USER_ROLES.USER, user_1.USER_ROLES.ADMIN, user_1.USER_ROLES.SUPER_ADMIN), // Protect route based on your needs
(0, validateRequest_1.default)(aiAssistant_validation_1.AiAssistantValidation.generateResponseZodSchema), aiAssistant_controller_1.AiAssistantController.generateResponse);
exports.AiAssistantRoutes = router;
