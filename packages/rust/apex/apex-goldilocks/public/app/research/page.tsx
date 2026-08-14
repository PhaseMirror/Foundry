import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import researchData from "@/content/research.json"

export default function ResearchPage() {
  const { projects, books } = researchData

  return (
    <div className="px-6 py-16 sm:py-24 lg:px-8 lg:py-32">
      <div className="container mx-auto">
        <div className="flex flex-col items-center gap-6 text-center mb-20">
          <h1 className="text-5xl font-bold tracking-tighter sm:text-6xl md:text-7xl">
            Research
          </h1>
          <p className="max-w-[800px] text-xl leading-relaxed text-muted-foreground md:text-2xl">
            Mathematical foundations and formal specifications powering Hologram
          </p>
        </div>

        <div className="max-w-6xl mx-auto space-y-20">
          {projects.map((project) => (
            <section key={project.id} id={project.id} className="scroll-mt-20">
              <Card className="transition-all hover:shadow-lg">
                <CardHeader className="pb-6">
                  <div className="flex items-start justify-between gap-4 mb-2">
                    <div className="flex-1">
                      <CardTitle className="text-3xl mb-2">{project.title}</CardTitle>
                      <p className="text-lg text-muted-foreground italic mb-4">{project.tagline}</p>
                      <div className="flex items-center gap-3 mb-4">
                        <Badge variant="outline" className="text-sm">
                          {project.status}
                        </Badge>
                        <a
                          href={project.github}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center text-sm text-primary hover:underline"
                        >
                          <svg className="h-4 w-4 mr-1" fill="currentColor" viewBox="0 0 24 24">
                            <path fillRule="evenodd" d="M12 2C6.477 2 2 6.484 2 12.017c0 4.425 2.865 8.18 6.839 9.504.5.092.682-.217.682-.483 0-.237-.008-.868-.013-1.703-2.782.605-3.369-1.343-3.369-1.343-.454-1.158-1.11-1.466-1.11-1.466-.908-.62.069-.608.069-.608 1.003.07 1.531 1.032 1.531 1.032.892 1.53 2.341 1.088 2.91.832.092-.647.35-1.088.636-1.338-2.22-.253-4.555-1.113-4.555-4.951 0-1.093.39-1.988 1.029-2.688-.103-.253-.446-1.272.098-2.65 0 0 .84-.27 2.75 1.026A9.564 9.564 0 0112 6.844c.85.004 1.705.115 2.504.337 1.909-1.296 2.747-1.027 2.747-1.027.546 1.379.202 2.398.1 2.651.64.7 1.028 1.595 1.028 2.688 0 3.848-2.339 4.695-4.566 4.943.359.309.678.92.678 1.855 0 1.338-.012 2.419-.012 2.747 0 .268.18.58.688.482A10.019 10.019 0 0022 12.017C22 6.484 17.522 2 12 2z" clipRule="evenodd" />
                          </svg>
                          View on GitHub
                        </a>
                      </div>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-8 pt-0">
                  <div>
                    <h3 className="text-xl font-semibold mb-3">Overview</h3>
                    <p className="text-base leading-relaxed text-muted-foreground">{project.description}</p>
                  </div>

                  <div>
                    <h3 className="text-xl font-semibold mb-3">Relationship to Hologram</h3>
                    <p className="text-base leading-relaxed text-muted-foreground">{project.relationship}</p>
                  </div>

                  <div>
                    <h3 className="text-xl font-semibold mb-3">Key Features</h3>
                    <ul className="grid gap-3 md:grid-cols-2">
                      {project.features.map((feature, idx) => (
                        <li key={idx} className="flex items-start gap-2">
                          <svg className="h-5 w-5 text-primary mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                          <span className="text-base text-muted-foreground">{feature}</span>
                        </li>
                      ))}
                    </ul>
                  </div>

                  <div>
                    <h3 className="text-xl font-semibold mb-3">Technologies</h3>
                    <div className="flex flex-wrap gap-2">
                      {project.technologies.map((tech, idx) => (
                        <Badge key={idx} variant="secondary" className="text-sm">
                          {tech}
                        </Badge>
                      ))}
                    </div>
                  </div>

                  <div>
                    <h3 className="text-xl font-semibold mb-3">Resources</h3>
                    <div className="flex flex-wrap gap-4">
                      {project.links.map((link, idx) => (
                        <a
                          key={idx}
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="inline-flex items-center text-base font-medium text-primary hover:underline"
                        >
                          {link.text}
                          <svg className="ml-2 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                          </svg>
                        </a>
                      ))}
                    </div>
                  </div>
                </CardContent>
              </Card>
            </section>
          ))}

          {/* Books Section */}
          <section className="mt-24">
            <div className="text-center mb-12">
              <h2 className="text-4xl font-bold mb-4">Documentation Books</h2>
              <p className="text-lg text-muted-foreground max-w-3xl mx-auto">
                Comprehensive technical documentation covering theory, formalization, and practical implementation
              </p>
            </div>
            <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
              {books.map((book) => (
                <Card key={book.id} className="transition-all hover:shadow-lg flex flex-col">
                  <CardHeader>
                    <CardTitle className="text-2xl">{book.title}</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-6 flex-1 flex flex-col">
                    <p className="text-base leading-relaxed text-muted-foreground flex-1">{book.description}</p>
                    
                    <div className="space-y-3 text-sm">
                      <div className="flex items-start gap-2">
                        <svg className="h-5 w-5 text-primary mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        <div>
                          <span className="font-semibold">Format:</span>{" "}
                          <span className="text-muted-foreground">{book.format}</span>
                        </div>
                      </div>
                      <div className="flex items-start gap-2">
                        <svg className="h-5 w-5 text-primary mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                        </svg>
                        <div>
                          <span className="font-semibold">Content:</span>{" "}
                          <span className="text-muted-foreground">{book.chapters}</span>
                        </div>
                      </div>
                    </div>

                    <div>
                      <h4 className="font-semibold text-sm mb-3">Topics Covered</h4>
                      <div className="flex flex-wrap gap-2">
                        {book.topics.map((topic) => (
                          <Badge key={topic} variant="outline" className="text-xs">
                            {topic}
                          </Badge>
                        ))}
                      </div>
                    </div>

                    <a
                      href={book.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center text-base font-semibold text-primary hover:underline mt-auto"
                    >
                      Read Online
                      <svg className="ml-2 h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
                      </svg>
                    </a>
                  </CardContent>
                </Card>
              ))}
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}
