const fs = require('fs');

// 1. Write layout.tsx
const layoutCode = `import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "NeuroFit Admin | AI-Powered Wellness Management",
  description: "Executive Management Portal for NeuroFit Health & Fitness Ecosystem",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased bg-[#F8FAFC] text-[#0F172A] min-h-screen">
        {children}
      </body>
    </html>
  );
}
`;

fs.writeFileSync('C:\\\\rohit projects\\\\neurofitadmin\\\\src\\\\app\\\\layout.tsx', layoutCode, 'utf8');
console.log('src/app/layout.tsx updated!');
