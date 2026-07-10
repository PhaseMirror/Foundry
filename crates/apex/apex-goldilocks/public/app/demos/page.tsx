import Link from "next/link";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import demosData from "@/content/demos.json";

export default function DemosPage() {
  const { hero, demos, labels, emptyState } = demosData;

  return (
    <div className="px-6 py-16 sm:py-24 lg:px-8 lg:py-32">
      <div className="container mx-auto">
        <div className="flex flex-col items-center gap-6 text-center mb-20">
          <h1 className="text-5xl font-bold tracking-tighter sm:text-6xl md:text-7xl">
            {hero.title}
          </h1>
          <p className="max-w-[800px] text-xl leading-relaxed text-muted-foreground md:text-2xl">
            {hero.description}
          </p>
        </div>

        <div className="grid gap-8 sm:grid-cols-1 lg:grid-cols-2">
          {demos.map((demo) => (
            <Card
              key={demo.id}
              className="transition-all hover:shadow-lg flex flex-col"
            >
              <CardHeader className="pb-4">
                <div className="flex items-start justify-between mb-3">
                  <div className="text-5xl mb-2">{demo.icon}</div>
                  <Badge
                    variant={demo.status === "available" ? "default" : "secondary"}
                    className={
                      demo.status === "available"
                        ? "bg-green-600 hover:bg-green-700"
                        : ""
                    }
                  >
                    {demo.status === "available" ? labels.available : labels.comingSoon}
                  </Badge>
                </div>
                <CardTitle className="text-2xl">{demo.title}</CardTitle>
                <CardDescription className="text-base">
                  {demo.category}
                </CardDescription>
              </CardHeader>
              <CardContent className="flex-1 flex flex-col gap-6 pt-0">
                <p className="text-base leading-relaxed text-muted-foreground">
                  {demo.description}
                </p>

                <div>
                  <h4 className="text-sm font-semibold mb-2">{labels.keyFeatures}</h4>
                  <ul className="space-y-1">
                    {demo.features.map((feature, idx) => (
                      <li
                        key={idx}
                        className="text-sm text-muted-foreground flex items-center gap-2"
                      >
                        <span className="text-primary">✓</span>
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>

                <div>
                  <h4 className="text-sm font-semibold mb-2">{labels.technology}</h4>
                  <div className="flex flex-wrap gap-2">
                    {demo.techStack.map((tech, idx) => (
                      <Badge key={idx} variant="outline" className="text-xs">
                        {tech}
                      </Badge>
                    ))}
                  </div>
                </div>

                <div className="mt-auto pt-4">
                  <Button
                    asChild
                    size="lg"
                    className="w-full h-12"
                    disabled={demo.status !== "available"}
                  >
                    <Link href={demo.href}>
                      {demo.status === "available"
                        ? labels.launchDemo
                        : labels.comingSoon}
                    </Link>
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {demos.length === 0 && (
          <div className="text-center py-20">
            <p className="text-xl text-muted-foreground">
              {emptyState.message}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
