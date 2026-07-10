import Image from "next/image"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import teamData from "@/content/team.json"

export default function AboutPage() {
  const { team } = teamData

  return (
    <div className="px-6 py-16 sm:py-24 lg:px-8 lg:py-32">
      <div className="container mx-auto">
        <div className="flex flex-col items-center gap-6 text-center mb-20">
          <h1 className="text-5xl font-bold tracking-tighter sm:text-6xl md:text-7xl">
            About Us
          </h1>
          <p className="max-w-[800px] text-xl leading-relaxed text-muted-foreground md:text-2xl">
            Meet the team building the future of compute acceleration through canonical form compilation
          </p>
        </div>

        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-3 max-w-7xl mx-auto mb-20">
        {team.map((member, index) => (
          <Card key={index} className="overflow-hidden transition-all hover:shadow-lg">
            <CardHeader className="pb-6">
              <div className="relative w-28 h-28 rounded-full overflow-hidden mb-6 shadow-lg">
                <Image
                  src={member.avatar}
                  alt={member.name}
                  fill
                  className="object-cover"
                  sizes="112px"
                />
              </div>
              <CardTitle className="text-2xl">{member.name}</CardTitle>
              <CardDescription className="text-lg font-medium text-primary mt-2">
                {member.role}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <p className="text-base leading-relaxed text-muted-foreground">
                {member.bio}
              </p>
              <div className="flex gap-3">
                {member.social.github && (
                  <a
                    href={member.social.github}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-foreground transition-colors"
                  >
                    <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" />
                    </svg>
                  </a>
                )}
                {member.social.twitter && (
                  <a
                    href={member.social.twitter}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-muted-foreground hover:text-foreground transition-colors"
                  >
                    <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                      <path d="M8.29 20.251c7.547 0 11.675-6.253 11.675-11.675 0-.178 0-.355-.012-.53A8.348 8.348 0 0022 5.92a8.19 8.19 0 01-2.357.646 4.118 4.118 0 001.804-2.27 8.224 8.224 0 01-2.605.996 4.107 4.107 0 00-6.993 3.743 11.65 11.65 0 01-8.457-4.287 4.106 4.106 0 001.27 5.477A4.072 4.072 0 012.8 9.713v.052a4.105 4.105 0 003.292 4.022 4.095 4.095 0 01-1.853.07 4.108 4.108 0 003.834 2.85A8.233 8.233 0 012 18.407a11.616 11.616 0 006.29 1.84" />
                    </svg>
                  </a>
                )}
              </div>
            </CardContent>
          </Card>
        ))}
        </div>

        <div className="max-w-5xl mx-auto space-y-8">
          <Card className="bg-gradient-to-br from-primary/5 to-secondary/5 border-primary/20">
            <CardHeader className="pb-6">
              <CardTitle className="text-3xl">Our Mission</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6 text-muted-foreground">
              <p className="text-lg leading-relaxed">
                Hologram is pioneering virtual AI compute acceleration—a revolutionary approach to solving the biggest 
                bottleneck in AI infrastructure: energy-efficient compute. As Sam Altman stated, achieving the gigawatt 
                AI infrastructure goal requires solving energy-efficient compute, the single biggest constraint on AI cost.
              </p>
              <p className="text-lg leading-relaxed">
                The real bottleneck lies below the framework level. While CPU scaling is limited by compute cycles, 
                GPU by memory and bus speed, and AI infrastructure by energy supply—the biggest inefficiencies live 
                beneath CUDA and PyTorch. With AI requiring 10% of US energy supply, we need a fundamental shift.
              </p>
              <p className="text-lg leading-relaxed">
                Hologram is a virtual hypervisor and compiler runtime that sits beneath existing frameworks, automatically 
                optimizing AI compute workloads. We deliver <strong className="text-foreground">3x throughput at 1/3 energy 
                with zero code or hardware changes</strong>, making high-performance compute universal, efficient, and scalable.
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-secondary/5 to-primary/5 border-secondary/20">
            <CardHeader className="pb-6">
              <CardTitle className="text-3xl">The Atlas Framework</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6 text-muted-foreground">
              <p className="text-lg leading-relaxed">
                At the heart of Hologram is Atlas—our Universal Lossless Encoding Framework. Atlas provides the 
                mathematical foundation for building virtual, accelerated HDC computation environments on any physical hardware.
              </p>
              <p className="text-lg leading-relaxed">
                Through <strong className="text-foreground">general application canonical data encoding</strong> and 
                <strong className="text-foreground"> lossless, byte-level encoding</strong>, Atlas enables 
                software-defined concurrent computation that virtualizes cloud and local compute across CUDA, PyTorch, 
                TensorFlow, LLVM, and Hugging Face ecosystems.
              </p>
            </CardContent>
          </Card>

          <Card className="border-primary/20">
            <CardHeader className="pb-6">
              <CardTitle className="text-3xl">Traction & Validation</CardTitle>
            </CardHeader>
            <CardContent className="space-y-6 text-muted-foreground">
              <div className="grid gap-6 md:grid-cols-2">
                <div className="space-y-2">
                  <h3 className="text-lg font-semibold text-foreground">🛰️ NASA JPL & Caltech</h3>
                  <p className="text-base">Working with Enterprise Neurosystems to apply our novel mathematical framework to telemetry data models for environmental reserve.</p>
                </div>
                <div className="space-y-2">
                  <h3 className="text-lg font-semibold text-foreground">🎯 Red Hat Community</h3>
                  <p className="text-base">Developers using Hologram to build low-energy geometric AI models for ARC-AGI competition, replacing expensive GPU stack.</p>
                </div>
                <div className="space-y-2">
                  <h3 className="text-lg font-semibold text-foreground">🦅 Uganda AI Lab</h3>
                  <p className="text-base">Government-sponsored AI lab using Hologram to build high-performance language models that run on standard non-GPU processors.</p>
                </div>
                <div className="space-y-2">
                  <h3 className="text-lg font-semibold text-foreground">🎓 Cornell University</h3>
                  <p className="text-base">Collaborating with computer research team to validate Hologram application in general application lossless HDC computing.</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}
