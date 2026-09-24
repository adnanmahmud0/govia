import express from 'express';
import { CommunityResourceController } from './communityResource.controller';
import validateRequest from '../../middlewares/validateRequest';
import { CommunityResourceValidation } from './communityResource.validation';
import auth from '../../middlewares/auth';
import { USER_ROLES } from '../../../enums/user';
import fileUploadHandler from '../../middlewares/fileUploadHandler';

const router = express.Router();

const allRoles = Object.values(USER_ROLES);

router.post(
  '/',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  fileUploadHandler(),
  validateRequest(CommunityResourceValidation.createCommunityResourceZodSchema),
  CommunityResourceController.createResource
);

router.get(
  '/',
  auth(...allRoles),
  CommunityResourceController.getAllResources
);

router.get(
  '/:id',
  auth(...allRoles),
  CommunityResourceController.getSingleResource
);

router.patch(
  '/:id',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  fileUploadHandler(),
  validateRequest(CommunityResourceValidation.updateCommunityResourceZodSchema),
  CommunityResourceController.updateResource
);

router.delete(
  '/:id',
  auth(USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN),
  CommunityResourceController.deleteResource
);

export const CommunityResourceRoutes = router;
