import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import fileUploadHandler from '../../middlewares/fileUploadHandler';
import { VaultController } from './vault.controller';

const router = express.Router();

const allRoles = [
  USER_ROLES.CITIZEN,
  USER_ROLES.USER,
  USER_ROLES.ATTORNEY,
  USER_ROLES.POLICE,
  USER_ROLES.BAIL_BONDSMAN,
  USER_ROLES.MENTAL_HEALTH_PROFESSIONAL,
  USER_ROLES.ADMIN,
  USER_ROLES.SUPER_ADMIN,
];

// Folders
router.post('/folders', auth(...allRoles), VaultController.createFolder);
router.get('/folders', auth(...allRoles), VaultController.getUserFolders);
router.get(
  '/folders/shared-with-me',
  auth(...allRoles),
  VaultController.getSharedWithMeFolders
);
router.post(
  '/folders/:id/share',
  auth(...allRoles),
  VaultController.shareFolder
);
router.get('/folders/:id', auth(...allRoles), VaultController.getFolderDetails);
router.patch('/folders/:id', auth(...allRoles), VaultController.updateFolder);
router.delete('/folders/:id', auth(...allRoles), VaultController.deleteFolder);

// Recordings across encounters and consultations
router.get('/recordings', auth(...allRoles), VaultController.getAllRecordings);

// Evidence Items
router.post(
  '/items/upload',
  auth(...allRoles),
  fileUploadHandler(),
  VaultController.uploadEvidence
);
router.post(
  '/items/link-meeting',
  auth(...allRoles),
  VaultController.linkMeetingToFolder
);
router.delete('/items/:id', auth(...allRoles), VaultController.deleteItem);

export const VaultRoutes = router;
