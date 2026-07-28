"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.HeroHighlightRoutes = void 0;
const express_1 = __importDefault(require("express"));
const heroHighlight_controller_1 = require("./heroHighlight.controller");
const validateRequest_1 = __importDefault(require("../../middlewares/validateRequest"));
const heroHighlight_validation_1 = require("./heroHighlight.validation");
const auth_1 = __importDefault(require("../../middlewares/auth"));
const user_1 = require("../../../enums/user");
const router = express_1.default.Router();
router.post('/', (0, auth_1.default)(user_1.USER_ROLES.USER, user_1.USER_ROLES.ADMIN, user_1.USER_ROLES.SUPER_ADMIN), // Add roles as appropriate for your app
(0, validateRequest_1.default)(heroHighlight_validation_1.HeroHighlightValidation.createHeroHighlightZodSchema), heroHighlight_controller_1.HeroHighlightController.createHeroHighlight);
router.get('/', (0, auth_1.default)(user_1.USER_ROLES.ADMIN, user_1.USER_ROLES.SUPER_ADMIN), // Usually getting all feedback is restricted, adjust if needed
heroHighlight_controller_1.HeroHighlightController.getHeroHighlights);
router.get('/:id', (0, auth_1.default)(user_1.USER_ROLES.ADMIN, user_1.USER_ROLES.SUPER_ADMIN), heroHighlight_controller_1.HeroHighlightController.getSingleHeroHighlight);
exports.HeroHighlightRoutes = router;
