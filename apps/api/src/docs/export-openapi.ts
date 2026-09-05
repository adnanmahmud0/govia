import fs from 'fs';
import path from 'path';
import { generateOpenApiDocument } from './generate-openapi';

export const exportOpenApiJson = () => {
  const doc = generateOpenApiDocument();
  const jsonContent = JSON.stringify(doc, null, 2);

  // Targets: postman/openapi.json and apps/api/src/docs/openapi.json
  const targets = [
    path.resolve(process.cwd(), 'postman', 'openapi.json'),
    path.resolve(process.cwd(), '..', '..', 'postman', 'openapi.json'),
    path.resolve(__dirname, 'openapi.json'),
  ];

  targets.forEach(target => {
    try {
      const dir = path.dirname(target);
      if (fs.existsSync(dir)) {
        fs.writeFileSync(target, jsonContent, 'utf-8');
        console.log(`Exported OpenAPI schema to: ${target}`);
      }
    } catch (err) {
      console.warn(`Could not write to ${target}:`, err);
    }
  });

  return doc;
};

if (require.main === module) {
  exportOpenApiJson();
}
