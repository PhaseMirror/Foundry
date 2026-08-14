import Image from "next/image"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import communityData from "@/content/community.json"

export default function CommunityPage() {
  const { members, social, highlights } = communityData

  return (
    <div className="px-6 py-16 sm:py-24 lg:px-8 lg:py-32">
      <div className="container mx-auto">
        <div className="flex flex-col items-center gap-6 text-center mb-20">
          <h1 className="text-5xl font-bold tracking-tighter sm:text-6xl md:text-7xl">
            Community
          </h1>
          <p className="max-w-[800px] text-xl leading-relaxed text-muted-foreground md:text-2xl">
            Join our thriving community of developers, researchers, and enthusiasts
          </p>
        </div>

        <div className="max-w-5xl mx-auto space-y-16">
        <section>
          <h2 className="text-3xl font-bold mb-10 text-center">Community Members</h2>
          <p className="text-center text-muted-foreground text-lg mb-12 max-w-3xl mx-auto">
            Meet the passionate developers, researchers, and contributors building the future of compute acceleration
          </p>
          <div className="grid gap-8 md:grid-cols-2 lg:grid-cols-3">
            {members.map((member, index) => (
              <Card key={index} className="overflow-hidden transition-all hover:shadow-lg">
                <CardHeader className="pb-6 text-center">
                  <div className="relative w-24 h-24 rounded-full overflow-hidden mx-auto mb-4 shadow-lg">
                    <Image
                      src={member.avatar}
                      alt={member.name}
                      fill
                      className="object-cover"
                      sizes="96px"
                    />
                  </div>
                  <CardTitle className="text-xl">{member.name}</CardTitle>
                  <CardDescription className="text-sm font-medium text-primary mt-1">
                    {member.role}
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4 pt-0">
                  <p className="text-sm leading-relaxed text-muted-foreground text-center">
                    {member.bio}
                  </p>
                  {/* Removed individual social icon links to avoid spotlighting specific personal accounts */}
                  <div className="h-4" />
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <section>
          <h2 className="text-3xl font-bold mb-10">Connect With Us</h2>
          <div className="grid gap-8 md:grid-cols-2">
            {Object.values(social).map((platform, index) => (
              <Card key={index} className="overflow-hidden transition-all hover:shadow-lg">
                <CardHeader className="pb-6">
                  <div className="flex items-center justify-between mb-3">
                    <CardTitle className="text-2xl">{platform.name}</CardTitle>
                    <div className="text-sm font-semibold text-primary">
                      {"members" in platform && typeof platform.members === 'string' && platform.members}
                      {"stars" in platform && typeof platform.stars === 'string' && platform.stars}
                      {"subscribers" in platform && typeof platform.subscribers === 'string' && platform.subscribers}
                    </div>
                  </div>
                  <CardDescription className="text-lg leading-relaxed">
                    {platform.description}
                  </CardDescription>
                </CardHeader>
                <CardContent className="pt-0">
                  <a
                    className="inline-flex items-center justify-center w-full gap-2 rounded-md border bg-background px-4 py-3 text-base font-medium shadow-sm transition-colors hover:bg-muted"
                    href={platform.url}
                    target="_blank"
                    rel="noopener noreferrer"
                  >
                    Visit {platform.name}
                    <svg className="ml-2 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                    </svg>
                  </a>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <section>
          <h2 className="text-3xl font-bold mb-10">Community Highlights</h2>
          <div className="grid gap-8 md:grid-cols-2">
            {highlights.map((highlight, index) => (
              <Card key={index} className="transition-all hover:shadow-lg">
                <CardHeader className="pb-6">
                  <div className="text-5xl mb-4">
                    {highlight.icon === 'users' && '👥'}
                    {highlight.icon === 'code' && '💻'}
                    {highlight.icon === 'calendar' && '📅'}
                    {highlight.icon === 'package' && '📦'}
                  </div>
                  <CardTitle className="text-2xl">{highlight.title}</CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                  <p className="text-base leading-relaxed text-muted-foreground">
                    {highlight.description}
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>

        <section>
          <Card className="bg-gradient-to-br from-primary/5 to-secondary/5 border-primary/20">
            <CardHeader className="pb-6">
              <CardTitle className="text-3xl">Get Involved</CardTitle>
              <CardDescription className="text-lg leading-relaxed">
                There are many ways to contribute to UOR Foundation and Hologram
              </CardDescription>
            </CardHeader>
            <CardContent className="pt-0 space-y-6">
              <div className="grid gap-6">
                <div className="flex items-start gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground text-base font-bold">
                    1
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold mb-2">Join the Community Forum</h3>
                    <p className="text-base leading-relaxed text-muted-foreground">
                      Participate in technical discussions on our Discourse forum. Topics include UOR protocols, geometric computing, canonical compilation, and AI acceleration research
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground text-base font-bold">
                    2
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold mb-2">Contribute on GitHub</h3>
                    <p className="text-base leading-relaxed text-muted-foreground">
                      Explore our open-source repositories: hologramapp, atlas-core, UOR protocols. Review code, report issues, submit pull requests, or start building your own applications
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground text-base font-bold">
                    3
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold mb-2">Connect on Discord & Twitter</h3>
                    <p className="text-base leading-relaxed text-muted-foreground">
                      Join real-time conversations on Discord and follow @UORFoundation on Twitter for updates, announcements, and community highlights
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground text-base font-bold">
                    4
                  </div>
                  <div>
                    <h3 className="text-lg font-semibold mb-2">Build & Share</h3>
                    <p className="text-base leading-relaxed text-muted-foreground">
                      Use Hologram to accelerate your AI workloads, experiment with Atlas geometric computing, or explore UOR protocols. Share your projects, benchmarks, and findings with the community
                    </p>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        </section>
        </div>
      </div>
    </div>
  )
}
