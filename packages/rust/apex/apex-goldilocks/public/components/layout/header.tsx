"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { ThemeToggle } from "./theme-toggle";
import { cn } from "@/lib/utils";

const navigation = [
  { name: "Demos", href: "/demos" },
  { name: "Research", href: "/research" },
  { name: "Community", href: "/community" },
  { name: "Contact", href: "/contact" },
  { name: "About", href: "/about" },
];

export function Header() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-20 items-end px-6 lg:px-8 pb-4">
        <div className="mr-8 flex">
          <Link href="/" className="flex items-center space-x-3">
            <div className="flex flex-col">
              <span className="text-xs text-muted-foreground mb-1">
                UOR Labs, powered by:
              </span>
              <div className="flex items-center space-x-3">
                <Image
                  src="/assets/hologram_pptx_media/hologram-logo.svg"
                  alt="Hologram"
                  width={40}
                  height={38}
                />
                <span className="font-bold text-2xl">Hologram</span>
              </div>
            </div>
          </Link>
        </div>
        <nav className="flex flex-1 items-center justify-between">
          <div className="flex items-center gap-8">
            {navigation.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  "text-base font-medium transition-colors hover:text-primary",
                  pathname === item.href
                    ? "text-foreground"
                    : "text-muted-foreground"
                )}
              >
                {item.name}
              </Link>
            ))}
          </div>
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
