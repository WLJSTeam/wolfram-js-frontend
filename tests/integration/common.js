import path from 'path';

export const delay = (ms) => {
  const promise = new Promise((resolve) => {
    setTimeout(resolve, ms)
  });

  return promise;
}

const checkIfKernelAttached = async (page) => {
  if (!page.kernelQ) {
    
  }
  await delay(2000);
  let kernelSelection = page.locator('button').filter({ hasText: 'Auto' });
  if (page.kernelQ) return;
  if (await kernelSelection.isVisible({timeout: 2000})) {
    kernelSelection.click();
    console.log('Attaching kernel');
    await delay(8000);
    page.kernelQ = true;
  } 
}

const os = process.platform;
const selectAllShortcut = os === 'darwin' ? 'Meta+A' : 'Control+A'; // macOS uses Meta (Cmd)
export const url = 'http://127.0.0.1:20560/iframe/'+encodeURIComponent(path.resolve(__dirname, 'notebook.wln'));

console.warn('Using url:'+url);

class Deferred {
  constructor() {
    this.promise = new Promise((resolve, reject)=> {
      this.reject = reject
      this.resolve = resolve
    })
  }
}

export const evaluate = async (page, input="1+1", timeout=5000, extra=500) => {
  if (!page.confirmDismissQ) {
    page.confirmDismissQ = true;
    page.on('dialog', async (dialog) => {
      dialog.accept();
      console.log('accepting kernel...');
      const d = new Deferred();
      page.kernelQ = d.promise;
      await delay(10000);
      d.resolve();
      console.log('done!');
      page.kernelQ = 9;
    });
  }
  const editor = page.locator('.cm-editor').first();
  // Click to focus
  await delay(200);
  await editor.click();
  await delay(200);
  // Type text into the editor
  await page.keyboard.type(input);
  await delay(400);
  await page.keyboard.type(' ');
  await delay(200);
  const play = page.locator('.button-cplay').first();
  play.click();

  if (page.kernelQ != 9) {
    await page.kernelQ;
  }
  
  await page.waitForSelector('.cout', {timeout:timeout});
  await delay(3.0*extra);
  const outputCell = page.locator('.cout').first();
  return outputCell;
}


export const clearCell = async (page, timeout=1000) => {
  let inputcell = page.locator('.cin').first();
  await inputcell.waitFor({ state: 'visible' });
  const id = await inputcell.getAttribute('id');

  const menu = page.locator('.button-cmore').first();
  menu.click();
  
  await page.locator('[id="dropdown-float"]').waitFor({ state: 'visible' });
  const clearOutputsButton = page.locator('button[data-name="RemoveCell"]').first();
  await clearOutputsButton.waitFor({ state: 'visible' }); // Ensures it appears
  await clearOutputsButton.click();

  inputcell = page.locator(`[id="${id}"]`);
  await inputcell.waitFor({ state: "detached" })
}