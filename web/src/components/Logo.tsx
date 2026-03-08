/** Inline SVG logo for ReturnClip (arrow + checkmark icon + wordmark) */
export default function Logo({ height = 30 }: { height?: number }) {
    const w = height * 4.5;
    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 360 80"
            height={height}
            width={w}
            aria-label="ReturnClip"
        >
            {/* Icon: curved arrow + checkmark */}
            <g>
                {/* Curved backward arrow (blue-purple) */}
                <path
                    d="M28 16 L48 16 L48 8 L68 28 L48 48 L48 40 L28 40
             C16 40 8 48 8 56 C8 64 16 72 28 72 L36 72"
                    fill="none"
                    stroke="#3B5BDB"
                    strokeWidth="7"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                />
                {/* Arrow head (blue) */}
                <path
                    d="M48 8 L68 28 L48 48"
                    fill="#3B5BDB"
                    opacity="0.9"
                />
                {/* Checkmark (teal) */}
                <path
                    d="M36 52 L48 64 L72 36"
                    fill="none"
                    stroke="#20C997"
                    strokeWidth="7"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                />
            </g>
            {/* Wordmark */}
            <text
                x="88"
                y="56"
                fontFamily="Inter, -apple-system, BlinkMacSystemFont, sans-serif"
                fontSize="38"
                fontWeight="700"
                fill="#1B2559"
                letterSpacing="-0.5"
            >
                ReturnClip
            </text>
        </svg>
    );
}
