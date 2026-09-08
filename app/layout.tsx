import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Petitie",
  description: "Onderteken dit initiatief",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="nl">
      <body>{children}</body>
    </html>
  );
}
