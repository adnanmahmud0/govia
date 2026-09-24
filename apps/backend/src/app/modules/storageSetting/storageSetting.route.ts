import express from 'express';
import { USER_ROLES } from '../../../enums/user';
import auth from '../../middlewares/auth';
import { StorageSettingController } from './storageSetting.controller';

const router = express.Router();
const adminRoles = [USER_ROLES.ADMIN, USER_ROLES.SUPER_ADMIN];

// Get current dynamic storage & LiveKit credentials
router.get('/', auth(...adminRoles), StorageSettingController.getStorageSetting);

// Save/update dynamic storage & LiveKit credentials
router.post('/', auth(...adminRoles), StorageSettingController.saveStorageSetting);
router.patch('/', auth(...adminRoles), StorageSettingController.saveStorageSetting);

// Test storage & LiveKit connection
router.post('/test-connection', auth(...adminRoles), StorageSettingController.testStorageConnection);

// Get all recordings with summary metrics & filters
router.get('/recordings', auth(...adminRoles), StorageSettingController.getAllRecordings);

// Delete recording from a meeting
router.delete('/recordings/:id', auth(...adminRoles), StorageSettingController.deleteRecording);

export const StorageSettingRoutes = router;
