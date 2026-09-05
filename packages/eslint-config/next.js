/** @type {import("eslint").Linter.Config} */
module.exports = {
  extends: ["next/core-web-vitals", "prettier"],
  rules: {
    "react-hooks/exhaustive-deps": "warn"
  }
};
