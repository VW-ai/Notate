import { useState } from 'react';

function App() {
  const [count, setCount] = useState(0);

  return (
    <main className="container">
      <h1>Notate</h1>
      <p>A lightweight personal knowledge layer</p>
      <div className="card">
        <button onClick={() => setCount((c) => c + 1)}>Count: {count}</button>
      </div>
      <p className="hint">
        Press <kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>Space</kbd> to open Quick Capture
      </p>
    </main>
  );
}

export default App;
