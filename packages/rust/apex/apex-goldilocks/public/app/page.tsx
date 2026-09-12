import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import landingData from "@/content/landing.json"

const iconMap: Record<string, string> = {
  zap: "⚡",
  cpu: "🔧",
  layers: "📚",
  gauge: "⏱️",
  globe: "🌍",
  sparkles: "✨"
}

export default function Home() {
  const { hero, features, stats } = landingData

  return (
    <div className="flex flex-col">
      <section className="relative overflow-hidden bg-gradient-to-b from-background to-muted/20 px-6 py-24 sm:py-32 lg:px-8 lg:py-40">
        <div className="absolute inset-0 -z-10 bg-[radial-gradient(45rem_50rem_at_top,theme(colors.primary/10%),transparent)]" />
        <div className="container mx-auto flex flex-col items-center justify-center gap-12">
          <div className="flex max-w-[980px] flex-col items-center gap-6 text-center">
            <h1 className="text-5xl font-bold leading-tight tracking-tighter md:text-7xl lg:text-8xl lg:leading-[1.1]">
              {hero.title}
            </h1>
            <p className="text-2xl font-medium text-muted-foreground md:text-3xl lg:text-4xl">
              {hero.subtitle}
            </p>
            {hero.tagline && (
              <p className="text-xl font-semibold text-primary md:text-2xl">
                {hero.tagline}
              </p>
            )}
            <div className="max-w-[850px] space-y-4 text-lg leading-relaxed sm:text-xl md:text-2xl">
              {hero.vision && (
                <p className="text-muted-foreground">
                  {hero.vision}
                </p>
              )}
              {hero.mission && (
                <p className="font-medium">
                  Our mission: <span className="text-primary">{hero.mission}</span>
                </p>
              )}
              <p className="text-muted-foreground">
                {hero.description}
              </p>
            </div>
          </div>
          <div className="flex flex-wrap items-center justify-center gap-4">
            <Button asChild size="lg" className="h-12 px-8 text-base">
              <Link href={hero.cta.primary.href}>{hero.cta.primary.text}</Link>
            </Button>
            <Button asChild variant="outline" size="lg" className="h-12 px-8 text-base">
              <Link href={hero.cta.secondary.href}>{hero.cta.secondary.text}</Link>
            </Button>
          </div>
          <div className="grid w-full grid-cols-1 gap-12 pt-12 sm:grid-cols-3">
            {stats.map((stat, index) => (
              <div key={index} className="flex flex-col items-center gap-3 text-center">
                <div className="text-5xl font-bold text-primary md:text-6xl">{stat.value}</div>
                <div className="text-base font-semibold md:text-lg">{stat.label}</div>
                <div className="text-sm text-muted-foreground">{stat.description}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="px-6 py-24 sm:py-32 lg:px-8">
        <div className="container mx-auto">
          <div className="flex flex-col items-center gap-6 text-center mb-16">
            <h2 className="text-4xl font-bold tracking-tighter sm:text-5xl md:text-6xl">
              Accessible High Performance Compute
            </h2>
            <p className="max-w-[800px] text-lg leading-relaxed text-muted-foreground md:text-xl">
              Universal, scalable, and efficient virtual infrastructure powered by Atlas
            </p>
          </div>
          <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
            {features.map((feature, index) => (
              <Card key={index} className="transition-all hover:shadow-lg">
                <CardHeader className="pb-4">
                  <div className="mb-4 text-5xl">{iconMap[feature.icon] || "📦"}</div>
                  <CardTitle className="text-xl">{feature.title}</CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                  <CardDescription className="text-base leading-relaxed">
                    {feature.description}
                  </CardDescription>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      <section className="bg-muted/30 px-6 py-24 sm:py-32 lg:px-8">
        <div className="container mx-auto">
          <div className="flex flex-col items-center gap-8 text-center">
            <div className="max-w-[900px] space-y-6">
              <h2 className="text-4xl font-bold tracking-tighter sm:text-5xl md:text-6xl">
                Universal Lossless Encoding Framework
              </h2>
              <div className="space-y-4 text-lg leading-relaxed text-muted-foreground md:text-xl">
                <p>
                  Hologram is powered by <span className="font-semibold text-primary">Atlas</span>, 
                  our breakthrough <span className="font-semibold text-foreground">general application canonical data encoding</span> framework.
                </p>
                <p>
                  Atlas provides the <span className="font-semibold text-foreground">mathematical foundation</span> for 
                  building virtual, accelerated HDC computation environments on any physical hardware, including CPUs and GPUs.
                </p>
                <p>
                  It achieves this through a <span className="font-semibold text-foreground">lossless, byte-level encoding</span> that 
                  transforms any data into universal, efficient, and scalable <span className="font-semibold text-foreground">software-defined concurrent computation</span>.
                </p>
              </div>
              <div className="pt-4">
                <Button asChild variant="outline" size="lg" className="h-12 px-8 text-base">
                  <Link href="/research">Learn More About Atlas →</Link>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
