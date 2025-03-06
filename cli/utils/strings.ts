export const camelCaseToWords = (s: string) =>
   s
      .replace(/([A-Z])/g, " $1")
      .charAt(0)
      .toUpperCase() + s.slice(1);
