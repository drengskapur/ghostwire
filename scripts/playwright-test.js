const { chromium } = require("playwright");

(async () => {
    const browser = await chromium.launch({
        headless: true,
        args: ["--no-sandbox", "--disable-setuid-sandbox"]
    });
    
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,
        viewport: { width: 1920, height: 1080 }
    });
    
    const page = await context.newPage();
    
    console.log("Navigating to:", process.env.GHOSTWIRE_URL);
    await page.goto(process.env.GHOSTWIRE_URL + "/?keyboard=1", {
        waitUntil: "networkidle",
        timeout: 30000
    });
    
    console.log("Waiting for page to load...");
    await page.waitForTimeout(5000);
    
    console.log("Taking screenshot...");
    await page.screenshot({
        path: "/screenshots/ghostwire-vnc.png",
        fullPage: true
    });
    
    console.log("✅ Test completed successfully");
    console.log("Title:", await page.title());
    
    await browser.close();
})().catch(err => {
    console.error("❌ Test failed:", err);
    process.exit(1);
});
