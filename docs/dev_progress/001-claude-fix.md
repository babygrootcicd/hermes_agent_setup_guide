---                                                                                                                               
  Fix Plan: posix_spawnp failed                                                                                                     
                                                                                                                                    
  Root Cause                                                                                                                        
                                                                                                                                    
  node-pty is a native C++ addon that must be compiled against Electron's specific ABI — not system Node.js. The                    
  app/node_modules/node-pty/build/Release/ directory does not exist, meaning the native .node binary was never built. When          
  pty.spawn() is called, it crashes with posix_spawnp failed.                                                                       
                                                                                                                                    
  ---                                                                                                                               
  Fix 1 — Rebuild node-pty for Electron (primary fix)                                                                               
                                                                                                                                    
  File: scripts/macos/build_app.sh                                                                                                  
                                                                                                                                    
  The current rebuild check uses --version which is unreliable. Replace it with a direct call to @electron/rebuild:                 
                                                                                                                                    
  # Replace the fragile version-check logic with:                                                                                   
  echo "🏗️   Rebuilding native modules for Electron..."                                                                              
  npx @electron/rebuild -f -w node-pty
                                                                                                                                    
  This compiles node-pty against the Electron runtime (not system Node.js v25), creating                                            
  node_modules/node-pty/build/Release/spawn-helper and pty.node.                                                                    
                                                                                                                                    
  ---             
  Fix 2 — PATH not available in packaged app (secondary fix)
                                                            
  File: app/main.js lines 97–103
                                                                                                                                    
  When launched from the DMG (outside Terminal), process.env won't contain the user's shell PATH customizations (~/.hermes/bin,     
  etc.). The hermes fallback to PATH will always fail silently.                                                                     
                                                                                                                                    
  Augment env before spawning to include known Hermes install locations:                                                            
  
  const spawnEnv = {                                                                                                                
    ...process.env,
    PATH: [
      path.join(homeDir, '.hermes', 'bin'),
      path.join(homeDir, '.local', 'bin'),                                                                                          
      '/usr/local/bin',
      '/opt/homebrew/bin',                                                                                                          
      process.env.PATH || ''
    ].join(':')                                                                                                                     
  };
  // then pass env: spawnEnv to pty.spawn                                                                                           
                                                                                                                                    
  ---
  Fix 3 — debug.sh has a broken open command                                                                                        
                                            
  File: scripts/macos/debug.sh line 21
                                                                                                                                    
  open -a is for .app bundles in /Applications, not DMG files. The path also has a placeholder xxx. Fix:                            
                                                                                                                                    
  open "dist/Hermes Agent-0.1.0-arm64.dmg"                                                                                          
                                                                                                                                    
  Also the script calls tail -f before open, so the user would never see the app launch (tail blocks). The tail should come after   
  open.                                                                                                                             
                                                                                                                                    
  ---             
  Fix 4 — electron-builder not including the compiled native binary
                                                                                                                                    
  File: app/package.json
                                                                                                                                    
  The "files" array in the build config includes **/* but native .node files inside build/Release/ may be stripped. Add an explicit 
  inclusion to be safe:
                                                                                                                                    
  "files": [      
    "**/*",
    "node_modules/node-pty/build/Release/**",
    "!dist"
  ]                                                                                                                                 
  
  ---                                                                                                                               
  Summary of changes

  ┌────────────────────────────┬────────────────────────────────────────────────────────────────┐
  │            File            │                             Change                             │
  ├────────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ scripts/macos/build_app.sh │ Use npx @electron/rebuild -f -w node-pty directly              │
  ├────────────────────────────┼────────────────────────────────────────────────────────────────┤
  │ app/main.js                │ Augment PATH in spawn env with Hermes locations                │                                   
  ├────────────────────────────┼────────────────────────────────────────────────────────────────┤                                   
  │ scripts/macos/debug.sh     │ Fix open command and reorder tail -f                           │                                   
  ├────────────────────────────┼────────────────────────────────────────────────────────────────┤                                   
  │ app/package.json           │ Explicitly include node-pty/build/Release/** in packaged files │
  └────────────────────────────┴────────────────────────────────────────────────────────────────┘                                   
                  