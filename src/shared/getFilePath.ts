import type { Express } from 'express';
type IFolderName = 'image' | 'media' | 'doc';

//single file
export const getSingleFilePath = (
  files: Partial<Record<IFolderName, Express.Multer.File[]>> | undefined,
  folderName: IFolderName
) => {
  const fileField = files && files[folderName];
  if (fileField && Array.isArray(fileField) && fileField.length > 0) {
    return `/${folderName}/${fileField[0].filename}`;
  }

  return undefined;
};

//multiple files
export const getMultipleFilesPath = (
  files: Partial<Record<IFolderName, Express.Multer.File[]>> | undefined,
  folderName: IFolderName
) => {
  const folderFiles = files && files[folderName];
  if (folderFiles) {
    if (Array.isArray(folderFiles)) {
      return folderFiles.map(
        (file: Express.Multer.File) => `/${folderName}/${file.filename}`
      );
    }
  }

  return undefined;
};
