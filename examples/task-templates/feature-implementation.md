# Task: Add "Copy to Clipboard" Feature to Code Blocks

## 🎯 Goal
Enhance the documentation site by adding a "Copy" button to all code blocks, allowing users to easily copy code snippets with a single click.

## 📝 Sub-tasks
- [x] Task 1: Research existing code block rendering logic.
- [ ] Task 2: Create a reusable `CopyButton` component.
- [ ] Task 3: Integrate `CopyButton` into the Markdown renderer.
- [ ] Task 4: Add CSS styles for the button (hover states, positioning).
- [ ] Task 5: Add a "Copied!" tooltip/feedback mechanism.

## 📂 Context
*Generated using `./scripts/common/gather_context.sh app/renderer.js app/styles.css`*

================================================================================
FILE: app/renderer.js
================================================================================
import { Marked } from 'marked';
import hljs from 'highlight.js';

const renderer = {
  code(code, infostring, escaped) {
    const lang = (infostring || '').match(/\S*/)[0];
    const highlighted = lang ? hljs.highlight(code, { language: lang }).value : code;
    
    return `
      <pre class="hljs">
        <code class="language-${lang}">${highlighted}</code>
      </pre>
    `;
  }
};

export const renderMarkdown = (content) => {
  const marked = new Marked({ renderer });
  return marked.parse(content);
};


================================================================================
FILE: app/styles.css
================================================================================
.hljs {
  position: relative;
  padding: 1em;
  background: #282c34;
  border-radius: 6px;
  overflow: auto;
}

code {
  font-family: 'Fira Code', monospace;
}


## 💡 Implementation Strategy
1.  Modify `renderer.code` in `app/renderer.js` to wrap the `<pre>` in a container.
2.  Inject a `<button class="copy-btn">Copy</button>` into that container.
3.  Add a global click listener or inline `onclick` that uses `navigator.clipboard.writeText`.
4.  Update `app/styles.css` to position the button in the top-right corner of the code block.

## 🧪 Verification Plan
1.  **Manual Test**: Open a page with a code block.
2.  **Functionality**: Click the "Copy" button and verify the content is in the clipboard.
3.  **Visual**: Ensure the button is visible on hover and doesn't obscure the code.
4.  **Feedback**: Verify the "Copied!" text appears briefly after clicking.
