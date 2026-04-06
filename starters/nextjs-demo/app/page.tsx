import Link from "next/link";
import styles from "./profile.module.css";

const services = [
  "Digital storytelling and workshop facilitation",
  "Training and learning content for care professionals",
  "Care-tech product strategy and implementation",
  "Public advocacy campaigns and inclusive communications",
];

const reasons = [
  "Domain expertise in dementia care and social justice",
  "Human-centered UX for elders, families, and care teams",
  "Cross-platform delivery across web and mobile",
  "AI-ready architecture with practical rollout support",
];

export default function Page() {
  return (
    <main className={styles.page}>
      <section className={styles.hero}>
        <h1>Powering Digital Innovation in Care Tech</h1>
        <p>
          Founded by Dr. Christopher Appiah-Thompson, World Class Scholars advances equity in
          disability, mental health, dementia care, education, and digital storytelling.
        </p>
      </section>

      <section className={styles.grid}>
        <article className={styles.card}>
          <h2>About World Class Scholars</h2>
          <p>
            We blend consultancy, creative media, and technology to design humane,
            trauma-aware, and culturally responsive care experiences.
          </p>
        </article>

        <article className={styles.card}>
          <h2>Why Choose Us for Your App?</h2>
          <ul>
            {reasons.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        </article>
      </section>

      <section className={styles.card}>
        <h2>Services</h2>
        <ul>
          {services.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>

      <section className={styles.card}>
        <h2>Contact</h2>
        <p>Let&apos;s collaborate on your next care-tech initiative.</p>
        <div className={styles.actions}>
          <a href="mailto:Christopher.appiahthompson@myworldclass.org" className={styles.button}>
            Email
          </a>
          <Link href="https://www.linkedin.com/in/christopher-appiah-thompson-a2014045" className={styles.button}>
            LinkedIn
          </Link>
          <Link href="https://worldclassscholars.org" className={styles.button}>
            Website
          </Link>
        </div>
      </section>
    </main>
  );
}
