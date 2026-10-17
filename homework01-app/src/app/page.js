import os from "os";

export default function Home() {
  // Reads the Linux machine hostname (e.g., "web-01" or "web-02") and capitalizes it
  const serverName = (process.env.SERVER_NAME || os.hostname() || "WEB-NODE").toUpperCase();
  const port = "3000";

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col justify-between p-6 sm:p-12 font-sans">
      {/* Top Header */}
      <header className="flex justify-between items-center border-b border-slate-800 pb-4 max-w-4xl w-full mx-auto">
        <span className="text-xs uppercase tracking-widest font-semibold text-emerald-400">
          ITE — DevOps Assignment
        </span>
        <span className="text-xs text-slate-400">Assignment #01</span>
      </header>

      {/* Main Content Card */}
      <main className="max-w-xl w-full mx-auto my-auto text-center space-y-8 bg-slate-900/60 p-8 sm:p-12 rounded-2xl border border-slate-800/80 shadow-2xl backdrop-blur-sm">
        <div className="space-y-2">
          <p className="text-sm font-medium text-slate-400">Production Node Environment</p>
          <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-white">
            React / Next.js Service
          </h1>
        </div>

        {/* Server Identifier Badge */}
        <div className="inline-flex flex-col items-center justify-center px-8 py-5 rounded-xl bg-slate-800 border-2 border-emerald-500/40 shadow-inner">
          <span className="text-xs uppercase font-medium text-emerald-400 mb-1">
            Active Host Node
          </span>
          <span className="text-5xl font-black tracking-wider text-emerald-400 font-mono">
            {serverName}
          </span>
        </div>

        {/* Deployment Metadata */}
        <div className="grid grid-cols-2 gap-4 text-left border-t border-slate-800 pt-6">
          <div className="bg-slate-950/50 p-3 rounded-lg border border-slate-800">
            <span className="text-xs text-slate-400 block">Service Port</span>
            <span className="font-mono text-sm text-slate-200">:{port}</span>
          </div>
          <div className="bg-slate-950/50 p-3 rounded-lg border border-slate-800">
            <span className="text-xs text-slate-400 block">Daemon</span>
            <span className="font-mono text-sm text-slate-200">systemd (Active)</span>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="text-center text-xs text-slate-400 border-t border-slate-800 pt-4 max-w-4xl w-full mx-auto">
        ITE Department • Automated Multi-Node Deployment
      </footer>
    </div>
  );
}

