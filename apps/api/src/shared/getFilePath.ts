import type { Express } from 'express';
type IFolderName = 'image' | 'media' | 'doc' | 'file' | 'attachment';

//single file
export const getSingleFilePath = (
  files: Partial<Record<string, Express.Multer.File[]>> | undefined,
  folderName: IFolderName
) => {
  const fileField = files && files[folderName];
  if (fileField && Array.isArray(fileField) && fileField.length > 0) {
    const targetFolder =
      folderName === 'image'
        ? 'image'
        : folderName === 'media'
        ? 'media'
        : 'doc';
    return `/${targetFolder}/${fileField[0].filename}`;
  }

  return undefined;
};

//multiple files
export const getMultipleFilesPath = (
  files: Partial<Record<string, Express.Multer.File[]>> | undefined,
  folderName: IFolderName
) => {
  const folderFiles = files && files[folderName];
  if (folderFiles) {
    if (Array.isArray(folderFiles)) {
      const targetFolder =
        folderName === 'image'
          ? 'image'
          : folderName === 'media'
          ? 'media'
          : 'doc';
      return folderFiles.map(
        (file: Express.Multer.File) => `/${targetFolder}/${file.filename}`
      );
    }
  }

  return undefined;
};
