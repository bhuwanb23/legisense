export interface CleanedText {
  text: string;
  stats: {
    originalLength: number;
    cleanedLength: number;
    garbageCharsRemoved: number;
    brokenWordsFixed: number;
  };
}

export function cleanOcrText(raw: string): CleanedText {
  const originalLength = raw.length;
  let text = raw;
  let garbageCharsRemoved = 0;
  let brokenWordsFixed = 0;

  const beforeGarbage = text.length;
  text = text.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, (match) => {
    garbageCharsRemoved++;
    return '';
  });
  garbageCharsRemoved += beforeGarbage - text.length;

  const beforeHyphen = text;
  text = text.replace(/(\w+)-\s*\n\s*(\w+)/g, (_match, part1: string, part2: string) => {
    brokenWordsFixed++;
    return part1 + part2;
  });
  brokenWordsFixed += [...beforeHyphen].filter((_, i) => beforeHyphen[i] !== text[i]).length / 2;

  text = text.replace(/\n{3,}/g, '\n\n');

  text = text.replace(/[ \t]{2,}/g, ' ');

  text = text.replace(/^[\s\-_*•·]+|[\s\-_*•·]+$/gm, '').replace(/^[\n]+|[\n]+$/g, '');

  text = text
    .split('\n')
    .map((line) => line.trim())
    .filter((line) => {
      if (line.length <= 1 && /[^a-zA-Z0-9.,!?;:'"()\-]/.test(line)) {
        garbageCharsRemoved += line.length;
        return false;
      }
      return true;
    })
    .join('\n');

  const cleanedLength = text.length;

  return {
    text,
    stats: {
      originalLength,
      cleanedLength,
      garbageCharsRemoved,
      brokenWordsFixed,
    },
  };
}
