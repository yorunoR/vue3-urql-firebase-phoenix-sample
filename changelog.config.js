module.exports = {
  disableEmoji: false,
  format: "{type}: {subject}",
  list: [
    "fix",
    "feat",
    "refactor",
    "test",
    "chore",
  ],
  maxMessageLength: 80,
  minMessageLength: 3,
  questions: ["type", "subject"],
  scopes: [],
  types: {
    chore: {
      description: "ドキュメント、ビルドプロセス、ライブラリなどの変更",
      value: "chore",
    },
    feat: {
      description: "機能追加",
      value: "feat",
    },
    fix: {
      description: "不具合の修正",
      value: "fix",
    },
    refactor: {
      description: "バグ修正や機能の追加を行わないコードの変更",
      value: "refactor",
    },
    test: {
      description: "テストコードの変更",
      value: "test",
    },
  },
};
